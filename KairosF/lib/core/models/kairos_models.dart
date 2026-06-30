enum MemoryType {
  bill,
  exam,
  assignment,
  meeting,
  subscription,
  travel,
  goal,
  note,
}

extension MemoryTypeLabel on MemoryType {
  String get label {
    return switch (this) {
      MemoryType.bill => 'Bill',
      MemoryType.exam => 'Exam',
      MemoryType.assignment => 'Assignment',
      MemoryType.meeting => 'Meeting',
      MemoryType.subscription => 'Subscription',
      MemoryType.travel => 'Travel',
      MemoryType.goal => 'Goal',
      MemoryType.note => 'Note',
    };
  }
}

enum ConfidenceLevel { high, medium, low }

extension ConfidenceLabel on ConfidenceLevel {
  String get label {
    return switch (this) {
      ConfidenceLevel.high => 'High',
      ConfidenceLevel.medium => 'Medium',
      ConfidenceLevel.low => 'Low',
    };
  }
}

enum WorkflowState { detected, approaching, critical, overdue, resolved }

extension WorkflowStateLabel on WorkflowState {
  String get label {
    return switch (this) {
      WorkflowState.detected => 'Detected',
      WorkflowState.approaching => 'Approaching',
      WorkflowState.critical => 'Critical',
      WorkflowState.overdue => 'Overdue',
      WorkflowState.resolved => 'Resolved',
    };
  }
}

class PriorityItem {
  const PriorityItem({
    required this.id,
    required this.title,
    required this.type,
    required this.dueLabel,
    required this.estimatedMinutes,
    required this.reasons,
    required this.workflowId,
    this.isAiGenerated = true,
  });

  final String id;
  final String title;
  final MemoryType type;
  final String dueLabel;
  final int estimatedMinutes;
  final List<String> reasons;
  final String workflowId;
  final bool isAiGenerated;
}

class RiskItem {
  const RiskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.dueLabel,
  });

  final String id;
  final String title;
  final String description;
  final ConfidenceLevel severity;
  final String dueLabel;
}

class DashboardData {
  const DashboardData({
    required this.nextMove,
    required this.everythingElse,
    required this.risks,
    required this.insights,
  });

  final PriorityItem? nextMove;
  final List<PriorityItem> everythingElse;
  final List<RiskItem> risks;
  final List<String> insights;

  bool get allClear =>
      nextMove == null && everythingElse.isEmpty && risks.isEmpty;

  DashboardData copyWith({
    PriorityItem? nextMove,
    List<PriorityItem>? everythingElse,
    List<RiskItem>? risks,
    List<String>? insights,
    bool clearNextMove = false,
  }) {
    return DashboardData(
      nextMove: clearNextMove ? null : nextMove ?? this.nextMove,
      everythingElse: everythingElse ?? this.everythingElse,
      risks: risks ?? this.risks,
      insights: insights ?? this.insights,
    );
  }
}

class Memory {
  const Memory({
    required this.id,
    required this.title,
    required this.type,
    required this.source,
    required this.confidence,
    required this.status,
    required this.updatedLabel,
    required this.metadata,
    required this.workflowId,
    this.confirmed = false,
  });

  final String id;
  final String title;
  final MemoryType type;
  final String source;
  final double confidence;
  final String status;
  final String updatedLabel;
  final Map<String, String> metadata;
  final String workflowId;
  final bool confirmed;

  ConfidenceLevel get confidenceLevel {
    if (confidence >= 0.9) return ConfidenceLevel.high;
    if (confidence >= 0.7) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  Memory copyWith({
    String? status,
    bool? confirmed,
    double? confidence,
    Map<String, String>? metadata,
  }) {
    return Memory(
      id: id,
      title: title,
      type: type,
      source: source,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      updatedLabel: updatedLabel,
      metadata: metadata ?? this.metadata,
      workflowId: workflowId,
      confirmed: confirmed ?? this.confirmed,
    );
  }
}

class WorkflowStep {
  const WorkflowStep({
    required this.label,
    required this.description,
    required this.complete,
  });

  final String label;
  final String description;
  final bool complete;
}

class Workflow {
  const Workflow({
    required this.id,
    required this.memoryId,
    required this.title,
    required this.typeLabel,
    required this.state,
    required this.snoozesUsed,
    required this.steps,
  });

  final String id;
  final String memoryId;
  final String title;
  final String typeLabel;
  final WorkflowState state;
  final int snoozesUsed;
  final List<WorkflowStep> steps;

  Workflow copyWith({
    WorkflowState? state,
    int? snoozesUsed,
    List<WorkflowStep>? steps,
  }) {
    return Workflow(
      id: id,
      memoryId: memoryId,
      title: title,
      typeLabel: typeLabel,
      state: state ?? this.state,
      snoozesUsed: snoozesUsed ?? this.snoozesUsed,
      steps: steps ?? this.steps,
    );
  }
}

class KairosNotification {
  const KairosNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdLabel,
    required this.deepLink,
    required this.read,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String createdLabel;
  final String deepLink;
  final bool read;

  KairosNotification copyWith({bool? read}) {
    return KairosNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      createdLabel: createdLabel,
      deepLink: deepLink,
      read: read ?? this.read,
    );
  }
}

class NeedsReviewItem {
  const NeedsReviewItem({
    required this.id,
    required this.title,
    required this.confidence,
    required this.extractedFields,
    required this.source,
  });

  final String id;
  final String title;
  final double confidence;
  final Map<String, String> extractedFields;
  final String source;

  ConfidenceLevel get confidenceLevel {
    if (confidence >= 0.9) return ConfidenceLevel.high;
    if (confidence >= 0.7) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }
}

class UserProfile {
  const UserProfile({
    required this.fullName,
    required this.email,
    required this.occupation,
    required this.kairosInboxAddress,
    required this.dailyBriefingTime,
    required this.timezone,
    required this.currency,
    required this.notificationIntensity,
    required this.pushEnabled,
    required this.emailEnabled,
  });

  final String fullName;
  final String email;
  final String occupation;
  final String kairosInboxAddress;
  final String dailyBriefingTime;
  final String timezone;
  final String currency;
  final double notificationIntensity;
  final bool pushEnabled;
  final bool emailEnabled;

  UserProfile copyWith({
    String? dailyBriefingTime,
    String? timezone,
    String? currency,
    double? notificationIntensity,
    bool? pushEnabled,
    bool? emailEnabled,
  }) {
    return UserProfile(
      fullName: fullName,
      email: email,
      occupation: occupation,
      kairosInboxAddress: kairosInboxAddress,
      dailyBriefingTime: dailyBriefingTime ?? this.dailyBriefingTime,
      timezone: timezone ?? this.timezone,
      currency: currency ?? this.currency,
      notificationIntensity:
          notificationIntensity ?? this.notificationIntensity,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
    );
  }
}
