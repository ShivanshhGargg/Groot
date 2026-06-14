Context
You are building the frontend for a manual task tracker (V1). Backend is Spring Boot with JWT authentication, PostgreSQL. All API endpoints are RESTful, return JSON, and require a Bearer token.

Design Direction
Inspiration: Apple Reminders, but cleaner and more refined.

Visual style: Minimalist, generous whitespace, soft shadows (shadow-sm, shadow-md), large corner radii (rounded-xl, rounded-2xl), subtle borders (border-gray-100/200).

Typography: SF Pro, Inter, or system‑font stack (font-sans).

Colours: Neutral background (bg-white or bg-gray-50), primary accent as a muted blue (#3b82f6 or #0a7bff), success green (#10b981), warning amber.

Dark mode (optional but nice): Tailwind’s dark: variant with a dark gray background.

Animations: Smooth transitions (transition-all duration-200), subtle hover scaling on cards, fade‑ins.

Core Pages / Layout
The app has a single‑page layout with three main areas:

Sidebar (left, width ~280px)

Shows list of goals.

Button “+ New Goal” opens a modal (title, deadline optional).

Each goal item shows title, deadline (if set), and a delete/edit icon.

Clicking a goal filters the calendar and task list to that goal.

Active goal is highlighted.

Main Area (center)

Weekly calendar (using FullCalendar or a custom React grid).

Shows Monday–Sunday, time slots optional (just days).

Tasks appear as coloured blocks inside the correct day column.

Block colour = goal colour (derive from goal id).

Block shows task title and estimated hours.

Drag & drop a task to a different day → calls PATCH /tasks/{id} with new due_date.

Clicking a task block opens the task edit modal.

Unscheduled sidebar (right, width ~260px)

Lists tasks with due_date = null.

Same block design, can drag from here onto calendar.

Header (top bar)

App title (“Task Tracker”).

User avatar / email, logout button.

Month navigation (previous/next week) if using calendar.

Components to Implement
Authentication Flow
Login / Signup pages (simple forms with email + password).

On success, store JWT in localStorage (or httpOnly cookie if backend supports). Attach to every API request as Authorization: Bearer <token>.

Protect routes – redirect to login if not authenticated.

Logout clears token and redirects.

Goal Management
GoalList (sidebar): fetch GET /api/goals.

CreateGoalModal: form with title, deadline (date picker). POST /api/goals.

EditGoalModal: same, with PUT /api/goals/{id}.

DeleteGoal: confirm dialog, then DELETE /api/goals/{id}.

Task Management
TaskCard component: displays title, estimated hours, status (pending/done), dependency info.

TaskModal (create/edit):

Title (text)

Estimated hours (number input, step 0.5)

Due date (date picker, optional)

Dependency: dropdown of other tasks in the same goal (not completed)

Goal (if not already selected)

On submit: POST /api/tasks or PUT /api/tasks/{id}.

Delete task: DELETE /api/tasks/{id}.

Completion Logging
When user clicks “Mark Done” on a task card → open CompletionModal.

Modal asks for actual hours spent (decimal, default = estimated hours).

On confirm: PATCH /api/tasks/{id}/complete with { actualHours }.

Task disappears from calendar / unscheduled sidebar (status becomes done).

Calendar Integration
Use FullCalendar (React wrapper) or build a custom week grid with react-beautiful-dnd or @dnd-kit.

Drag & drop:

On drop, call PATCH /api/tasks/{id} with new due_date.

Refresh calendar data from backend.

Dependencies (visual only):

If Task B depends on Task A, show a small tooltip or icon on Task B. No automatic enforcement.

Data Fetching & State
Use React Context or Zustand for:

Auth state (user, token).

Current selected goal.

Goals, tasks, calendar data.

Fetch all data on page load:
GET /api/goals → GET /api/tasks?goalId=... (or fetch all tasks and filter client‑side).

After any mutation (create, update, delete, complete, drag‑drop), refetch relevant data.

API Endpoints (Expected from Backend)
text
POST   /api/auth/login          → { token, user }
POST   /api/auth/register       → { user }
GET    /api/goals               → [Goal]
POST   /api/goals               → Goal
PUT    /api/goals/{id}          → Goal
DELETE /api/goals/{id}
GET    /api/tasks?goalId=...    → [Task]
POST   /api/tasks               → Task
PUT    /api/tasks/{id}          → Task
DELETE /api/tasks/{id}
PATCH  /api/tasks/{id}/complete → { actualHours } → Task
PATCH  /api/tasks/{id}          → { dueDate } (for drag‑drop)
User Experience Must‑Haves (from V1 checklist)
Add a goal → appears instantly in sidebar.

Add tasks under that goal (with dependencies) → calendar shows blocks.

Mark task as done → actual hours popup, task removed from calendar.

Edit task duration → calendar block resizes (height based on hours? or just text updates).

Delete a goal → all its tasks vanish.

Drag‑drop task on calendar → due date updates, persists after reload.

Reload page → all data restored exactly.

No AI, no auto‑scheduling, no analytics – this is V1.

Tech Stack (already given)
React 18+

TypeScript

Tailwind CSS (with PostCSS)

Axios for API calls

React Router DOM for routing

FullCalendar (or @dnd-kit/sortable + custom grid)

React Hook Form + Zod (optional but recommended)

Acceptance Criteria (Frontend Only)
All checklist items above work end‑to‑end with the Spring Boot backend.

UI looks clean, modern, and responsive (mobile – hamburger sidebar, but desktop first).

No console errors; TypeScript strict mode passes.

Drag & drop feels smooth; modals are accessible (focus trap, ESC to close).

