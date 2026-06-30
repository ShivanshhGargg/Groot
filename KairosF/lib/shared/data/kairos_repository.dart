import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/kairos_models.dart';

final kairosRepositoryProvider =
    StateNotifierProvider<KairosRepository, KairosData>((ref) {
  return KairosRepository();
});

class KairosData {
  const KairosData({
    required this.dashboard,
    required this.memories,
    required this.workflows,
    required this.notifications,
    required this.needsReview,
    required this.profile,
    required this.rawNotes,
  });

  final DashboardData dashboard;
  final List<Memory> memories;
  final List<Workflow> workflows;
  final List<KairosNotification> notifications;
  final List<NeedsReviewItem> needsReview;
  final UserProfile profile;
  final List<String> rawNotes;

  Memory? memoryById(String id) {
    for (final memory in memories) {
      if (memory.id == id) return memory;
    }
    return null;
  }

  Workflow? workflowById(String id) {
    for (final workflow in workflows) {
      if (workflow.id == id) return workflow;
    }
    return null;
  }

  KairosData copyWith({
    DashboardData? dashboard,
    List<Memory>? memories,
    List<Workflow>? workflows,
    List<KairosNotification>? notifications,
    List<NeedsReviewItem>? needsReview,
    UserProfile? profile,
    List<String>? rawNotes,
  }) {
    return KairosData(
      dashboard: dashboard ?? this.dashboard,
      memories: memories ?? this.memories,
      workflows: workflows ?? this.workflows,
      notifications: notifications ?? this.notifications,
      needsReview: needsReview ?? this.needsReview,
      profile: profile ?? this.profile,
      rawNotes: rawNotes ?? this.rawNotes,
    );
  }
}

class KairosRepository extends StateNotifier<KairosData> {
  KairosRepository() : super(_seedData);

  void submitText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final nowId = DateTime.now().microsecondsSinceEpoch.toString();
    final reviewItem = NeedsReviewItem(
      id: 'review-$nowId',
      title: _titleFromText(trimmed),
      confidence: 0.68,
      extractedFields: {
        'Detected text': trimmed,
        'Suggested type': 'Needs classification',
        'Date': 'Not confirmed',
      },
      source: 'Text intake',
    );

    state = state.copyWith(
      needsReview: [reviewItem, ...state.needsReview],
      notifications: [
        KairosNotification(
          id: 'note-$nowId',
          title: 'New item needs review',
          body: reviewItem.title,
          type: 'Extraction',
          createdLabel: 'Just now',
          deepLink: '/inbox',
          read: false,
        ),
        ...state.notifications,
      ],
    );
  }

  void confirmReview(String id) {
    final item = _firstReviewOrNull(id);
    if (item == null) return;

    final memoryId = 'memory-${DateTime.now().millisecondsSinceEpoch}';
    final workflowId = 'workflow-${DateTime.now().millisecondsSinceEpoch}';
    final memory = Memory(
      id: memoryId,
      title: item.title,
      type: MemoryType.note,
      source: item.source,
      confidence: item.confidence,
      status: 'Pending Confirmation',
      updatedLabel: 'Just now',
      metadata: item.extractedFields,
      workflowId: workflowId,
      confirmed: true,
    );

    final workflow = Workflow(
      id: workflowId,
      memoryId: memoryId,
      title: item.title,
      typeLabel: 'Review',
      state: WorkflowState.detected,
      snoozesUsed: 0,
      steps: const [
        WorkflowStep(
          label: 'Detected',
          description: 'Information captured from intake.',
          complete: true,
        ),
        WorkflowStep(
          label: 'Confirmed',
          description: 'Ready for priority calculation.',
          complete: false,
        ),
      ],
    );

    state = state.copyWith(
      needsReview: [
        for (final entry in state.needsReview)
          if (entry.id != id) entry,
      ],
      memories: [memory, ...state.memories],
      workflows: [workflow, ...state.workflows],
    );
  }

  void ignoreReview(String id) {
    final item = _firstReviewOrNull(id);
    if (item == null) return;
    state = state.copyWith(
      needsReview: [
        for (final entry in state.needsReview)
          if (entry.id != id) entry,
      ],
      rawNotes: [item.title, ...state.rawNotes],
    );
  }

  void completeNextMove() {
    final dashboard = state.dashboard;
    if (dashboard.nextMove == null) return;

    final nextQueue = [...dashboard.everythingElse];
    final promoted = nextQueue.isEmpty ? null : nextQueue.removeAt(0);

    state = state.copyWith(
      dashboard: dashboard.copyWith(
        nextMove: promoted,
        everythingElse: nextQueue,
        insights: [
          'You completed one commitment today.',
          ...dashboard.insights,
        ],
        clearNextMove: promoted == null,
      ),
    );
  }

  void snoozeNextMove() {
    final dashboard = state.dashboard;
    final nextMove = dashboard.nextMove;
    if (nextMove == null) return;

    final nextQueue = [...dashboard.everythingElse, nextMove];
    state = state.copyWith(
      dashboard: dashboard.copyWith(
        nextMove: nextQueue.removeAt(0),
        everythingElse: nextQueue,
      ),
    );
  }

  void markNotificationRead(String id) {
    state = state.copyWith(
      notifications: [
        for (final notification in state.notifications)
          notification.id == id
              ? notification.copyWith(read: true)
              : notification,
      ],
    );
  }

  void markAllNotificationsRead() {
    state = state.copyWith(
      notifications: [
        for (final notification in state.notifications)
          notification.copyWith(read: true),
      ],
    );
  }

  void confirmMemory(String id) {
    state = state.copyWith(
      memories: [
        for (final memory in state.memories)
          memory.id == id
              ? memory.copyWith(
                  status: 'Confirmed',
                  confirmed: true,
                  confidence: memory.confidence < 0.92 ? 0.92 : memory.confidence,
                )
              : memory,
      ],
    );
  }

  void snoozeWorkflow(String id) {
    state = state.copyWith(
      workflows: [
        for (final workflow in state.workflows)
          workflow.id == id
              ? workflow.copyWith(snoozesUsed: workflow.snoozesUsed + 1)
              : workflow,
      ],
    );
  }

  void resolveWorkflow(String id) {
    state = state.copyWith(
      workflows: [
        for (final workflow in state.workflows)
          workflow.id == id
              ? workflow.copyWith(state: WorkflowState.resolved)
              : workflow,
      ],
    );
  }

  void updateProfile({
    String? dailyBriefingTime,
    double? notificationIntensity,
    bool? pushEnabled,
    bool? emailEnabled,
  }) {
    state = state.copyWith(
      profile: state.profile.copyWith(
        dailyBriefingTime: dailyBriefingTime,
        notificationIntensity: notificationIntensity,
        pushEnabled: pushEnabled,
        emailEnabled: emailEnabled,
      ),
    );
  }

  static String _titleFromText(String text) {
    if (text.length <= 42) return text;
    return '${text.substring(0, 39).trim()}...';
  }

  NeedsReviewItem? _firstReviewOrNull(String id) {
    for (final entry in state.needsReview) {
      if (entry.id == id) return entry;
    }
    return null;
  }
}

const _seedData = KairosData(
  dashboard: DashboardData(
    nextMove: PriorityItem(
      id: 'priority-dbms',
      title: 'Finish DBMS assignment',
      type: MemoryType.assignment,
      dueLabel: 'Today, 6:00 PM',
      estimatedMinutes: 45,
      reasons: [
        'Exam in 4 days',
        'Assignment contributes 15%',
        'You have one clear work block this afternoon',
      ],
      workflowId: 'workflow-dbms',
    ),
    everythingElse: [
      PriorityItem(
        id: 'priority-hostel',
        title: 'Pay hostel fee',
        type: MemoryType.bill,
        dueLabel: 'Tomorrow',
        estimatedMinutes: 10,
        reasons: ['Payment due within 24 hours'],
        workflowId: 'workflow-hostel',
      ),
      PriorityItem(
        id: 'priority-linked-lists',
        title: 'Review linked lists',
        type: MemoryType.exam,
        dueLabel: 'This evening',
        estimatedMinutes: 35,
        reasons: ['High exam impact topic'],
        workflowId: 'workflow-linked-lists',
      ),
      PriorityItem(
        id: 'priority-project-call',
        title: 'Call project teammate',
        type: MemoryType.meeting,
        dueLabel: 'Before 8:00 PM',
        estimatedMinutes: 15,
        reasons: ['Waiting on teammate confirmation'],
        workflowId: 'workflow-project-call',
      ),
      PriorityItem(
        id: 'priority-netflix',
        title: 'Confirm Netflix renewal',
        type: MemoryType.subscription,
        dueLabel: 'In 2 days',
        estimatedMinutes: 5,
        reasons: ['Amount missing from extraction'],
        workflowId: 'workflow-netflix',
      ),
      PriorityItem(
        id: 'priority-flight',
        title: 'Check flight baggage rules',
        type: MemoryType.travel,
        dueLabel: 'This week',
        estimatedMinutes: 12,
        reasons: ['Travel booking detected'],
        workflowId: 'workflow-flight',
      ),
    ],
    risks: [
      RiskItem(
        id: 'risk-dbms',
        title: 'DBMS exam approaching',
        description: 'The exam is in 4 days and two prep tasks are open.',
        severity: ConfidenceLevel.medium,
        dueLabel: '4 days',
      ),
      RiskItem(
        id: 'risk-electricity',
        title: 'Electricity bill due',
        description: 'Bill enters critical state in less than 24 hours.',
        severity: ConfidenceLevel.high,
        dueLabel: 'Tomorrow',
      ),
      RiskItem(
        id: 'risk-project',
        title: 'Project submission ambiguity',
        description: 'Owner and final upload time are not confirmed.',
        severity: ConfidenceLevel.low,
        dueLabel: 'This week',
      ),
    ],
    insights: [
      'You completed 4 commitments this week.',
      'You have 2 upcoming deadlines.',
      'Most ignored items are bills and subscriptions.',
    ],
  ),
  memories: [
    Memory(
      id: 'memory-dbms',
      title: 'DBMS assignment',
      type: MemoryType.assignment,
      source: 'PDF upload',
      confidence: 0.95,
      status: 'Active',
      updatedLabel: 'Today',
      metadata: {
        'Due date': 'Today, 6:00 PM',
        'Course': 'DBMS',
        'Estimated time': '45 minutes',
      },
      workflowId: 'workflow-dbms',
    ),
    Memory(
      id: 'memory-electricity',
      title: 'Electricity bill',
      type: MemoryType.bill,
      source: 'Screenshot',
      confidence: 0.91,
      status: 'Critical',
      updatedLabel: 'Yesterday',
      metadata: {
        'Amount': 'INR 1,840',
        'Due date': 'Tomorrow',
        'Provider': 'Utility account',
      },
      workflowId: 'workflow-electricity',
    ),
    Memory(
      id: 'memory-netflix',
      title: 'Netflix renewal',
      type: MemoryType.subscription,
      source: 'Forwarded email',
      confidence: 0.72,
      status: 'Pending Confirmation',
      updatedLabel: '2 hours ago',
      metadata: {
        'Renewal date': 'September 15',
        'Amount': 'Not found',
        'Vendor': 'Netflix',
      },
      workflowId: 'workflow-netflix',
    ),
    Memory(
      id: 'memory-flight',
      title: 'Delhi flight ticket',
      type: MemoryType.travel,
      source: 'Kairos Inbox',
      confidence: 0.88,
      status: 'Active',
      updatedLabel: 'Yesterday',
      metadata: {
        'Flight': 'AI 441',
        'Departure': 'Friday, 9:20 AM',
        'PNR': 'Hidden',
      },
      workflowId: 'workflow-flight',
    ),
    Memory(
      id: 'memory-linked-lists',
      title: 'Linked lists revision',
      type: MemoryType.exam,
      source: 'Text note',
      confidence: 0.93,
      status: 'Active',
      updatedLabel: 'Today',
      metadata: {
        'Topic': 'Data Structures',
        'Exam date': 'In 4 days',
        'Priority': 'High',
      },
      workflowId: 'workflow-linked-lists',
    ),
  ],
  workflows: [
    Workflow(
      id: 'workflow-dbms',
      memoryId: 'memory-dbms',
      title: 'DBMS assignment workflow',
      typeLabel: 'Assignment',
      state: WorkflowState.critical,
      snoozesUsed: 1,
      steps: [
        WorkflowStep(
          label: 'Scheduled',
          description: 'Assignment extracted from uploaded PDF.',
          complete: true,
        ),
        WorkflowStep(
          label: 'Week-Out',
          description: 'Prep reminder shown in daily briefing.',
          complete: true,
        ),
        WorkflowStep(
          label: 'Day-Before',
          description: 'Moved to risks and next move candidates.',
          complete: true,
        ),
        WorkflowStep(
          label: 'Completed',
          description: 'Waiting for user confirmation.',
          complete: false,
        ),
      ],
    ),
    Workflow(
      id: 'workflow-electricity',
      memoryId: 'memory-electricity',
      title: 'Electricity bill workflow',
      typeLabel: 'Bill',
      state: WorkflowState.critical,
      snoozesUsed: 2,
      steps: [
        WorkflowStep(
          label: 'Detected',
          description: 'Bill found in screenshot.',
          complete: true,
        ),
        WorkflowStep(
          label: 'Approaching',
          description: 'Due within 3-7 days.',
          complete: true,
        ),
        WorkflowStep(
          label: 'Critical',
          description: 'Due in less than 48 hours.',
          complete: true,
        ),
        WorkflowStep(
          label: 'Resolved',
          description: 'Payment not confirmed yet.',
          complete: false,
        ),
      ],
    ),
    Workflow(
      id: 'workflow-netflix',
      memoryId: 'memory-netflix',
      title: 'Netflix renewal workflow',
      typeLabel: 'Subscription',
      state: WorkflowState.approaching,
      snoozesUsed: 0,
      steps: [
        WorkflowStep(
          label: 'Detected',
          description: 'Renewal date extracted from email.',
          complete: true,
        ),
        WorkflowStep(
          label: 'Approaching',
          description: 'Amount is missing, user confirmation needed.',
          complete: true,
        ),
        WorkflowStep(
          label: 'Resolved',
          description: 'Waiting for decision.',
          complete: false,
        ),
      ],
    ),
    Workflow(
      id: 'workflow-flight',
      memoryId: 'memory-flight',
      title: 'Flight preparation workflow',
      typeLabel: 'Travel',
      state: WorkflowState.detected,
      snoozesUsed: 0,
      steps: [
        WorkflowStep(
          label: 'Detected',
          description: 'Flight ticket parsed from Kairos Inbox.',
          complete: true,
        ),
        WorkflowStep(
          label: 'Prepare',
          description: 'Check baggage and document requirements.',
          complete: false,
        ),
      ],
    ),
    Workflow(
      id: 'workflow-linked-lists',
      memoryId: 'memory-linked-lists',
      title: 'Linked lists revision workflow',
      typeLabel: 'Exam',
      state: WorkflowState.approaching,
      snoozesUsed: 0,
      steps: [
        WorkflowStep(
          label: 'Scheduled',
          description: 'Exam topic added to study plan.',
          complete: true,
        ),
        WorkflowStep(
          label: 'Week-Out',
          description: 'Revision block suggested.',
          complete: true,
        ),
        WorkflowStep(
          label: 'Completed',
          description: 'Pending review session.',
          complete: false,
        ),
      ],
    ),
  ],
  notifications: [
    KairosNotification(
      id: 'notification-briefing',
      title: 'Daily briefing ready',
      body: 'One next move, five other items, and three risks.',
      type: 'Daily Briefing',
      createdLabel: '8:00 AM',
      deepLink: '/home',
      read: false,
    ),
    KairosNotification(
      id: 'notification-bill',
      title: 'Bill enters critical state',
      body: 'Electricity bill is due tomorrow.',
      type: 'Workflow',
      createdLabel: 'Yesterday',
      deepLink: '/workflow/workflow-electricity',
      read: false,
    ),
    KairosNotification(
      id: 'notification-extraction',
      title: 'Extraction needs review',
      body: 'Netflix renewal amount was not found.',
      type: 'Extraction',
      createdLabel: '2 hours ago',
      deepLink: '/inbox',
      read: true,
    ),
  ],
  needsReview: [
    NeedsReviewItem(
      id: 'review-netflix',
      title: 'Netflix subscription',
      confidence: 0.72,
      source: 'Forwarded email',
      extractedFields: {
        'Renewal date': 'September 15',
        'Amount': 'Not found',
        'Vendor': 'Netflix',
      },
    ),
    NeedsReviewItem(
      id: 'review-project',
      title: 'Project submission',
      confidence: 0.64,
      source: 'Screenshot',
      extractedFields: {
        'Due date': 'Friday',
        'Owner': 'Not found',
        'Submission link': 'Detected',
      },
    ),
  ],
  profile: UserProfile(
    fullName: 'Shivansh',
    email: 'shivansh@example.com',
    occupation: 'Student',
    kairosInboxAddress: 'Kairos+shivansh@Kairos.ai',
    dailyBriefingTime: '08:00',
    timezone: 'Asia/Kolkata',
    currency: 'INR',
    notificationIntensity: 0.55,
    pushEnabled: true,
    emailEnabled: false,
  ),
  rawNotes: [
    'Ambiguous screenshot from shopping app',
    'Unknown meeting note from pasted text',
  ],
);
