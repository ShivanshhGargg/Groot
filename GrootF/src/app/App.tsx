import React, {
  useState, useContext, createContext, useEffect, useMemo, useCallback,
} from "react";
import { BrowserRouter, Routes, Route, Navigate, useNavigate } from "react-router";
import { DndProvider, useDrag, useDrop } from "react-dnd";
import { HTML5Backend } from "react-dnd-html5-backend";
import { format, startOfWeek, addDays, addWeeks, subWeeks, isSameDay, parseISO, isValid, isPast } from "date-fns";
import {
  Plus, Trash2, Edit2, ChevronLeft, ChevronRight, LogOut,
  Clock, CheckCircle2, X, Target, Inbox, Link2, Calendar,
  Circle, ChevronDown, Loader2,
} from "lucide-react";
import * as Dialog from "@radix-ui/react-dialog";
import axios from "axios";

// ─── Types ────────────────────────────────────────────────────────────────────

interface User { id: number; email: string; }

interface Goal {
  id: number;
  title: string;
  deadline?: string;
  color: string;
}

interface Task {
  id: number;
  goalId: number;
  title: string;
  estimatedHours: number;
  dueDate?: string;
  status: "pending" | "done";
  dependencyId?: number;
  actualHours?: number;
}

// ─── Constants ────────────────────────────────────────────────────────────────

const GOAL_COLORS = [
  "#3b82f6", "#10b981", "#8b5cf6", "#f59e0b",
  "#ef4444", "#06b6d4", "#ec4899", "#84cc16",
];

const api = axios.create({ baseURL: "/api" });
api.interceptors.request.use((cfg) => {
  const t = localStorage.getItem("token");
  if (t) cfg.headers.Authorization = `Bearer ${t}`;
  return cfg;
});

// ─── Seed data (demo mode) ────────────────────────────────────────────────────

const SEED_GOALS: Goal[] = [
  { id: 1, title: "Q3 Product Launch", deadline: "2026-09-30", color: "#3b82f6" },
  { id: 2, title: "Personal Development", deadline: "2026-07-31", color: "#10b981" },
  { id: 3, title: "Side Project", color: "#8b5cf6" },
];

const SEED_TASKS: Task[] = [
  { id: 1, goalId: 1, title: "Design system audit", estimatedHours: 2, dueDate: "2026-06-09", status: "pending" },
  { id: 2, goalId: 1, title: "API documentation", estimatedHours: 1.5, dueDate: "2026-06-10", status: "pending" },
  { id: 3, goalId: 2, title: "TypeScript deep dive", estimatedHours: 2, dueDate: "2026-06-10", status: "pending" },
  { id: 4, goalId: 1, title: "Sprint review prep", estimatedHours: 1, dueDate: "2026-06-11", status: "pending" },
  { id: 5, goalId: 1, title: "Refactor auth module", estimatedHours: 3, dueDate: "2026-06-12", status: "pending", dependencyId: 4 },
  { id: 6, goalId: 3, title: "Portfolio update", estimatedHours: 2, dueDate: "2026-06-13", status: "pending" },
  { id: 7, goalId: 1, title: "Write unit tests", estimatedHours: 2, status: "pending" },
  { id: 8, goalId: 1, title: "Update dependencies", estimatedHours: 1, status: "pending" },
  { id: 9, goalId: 2, title: "Read SICP chapter 3", estimatedHours: 1.5, status: "pending" },
];

// ─── Auth Context ─────────────────────────────────────────────────────────────

interface AuthCtx {
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthCtx>(null!);
const useAuth = () => useContext(AuthContext);

function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(() => {
    try { return JSON.parse(localStorage.getItem("user") || "null"); } catch { return null; }
  });

  const login = async (email: string, password: string) => {
    try {
      const { data } = await api.post("/auth/login", { email, password });
      localStorage.setItem("token", data.token);
      localStorage.setItem("user", JSON.stringify(data.user));
      setUser(data.user);
    } catch {
      // demo fallback
      const u = { id: 1, email };
      localStorage.setItem("token", "demo");
      localStorage.setItem("user", JSON.stringify(u));
      setUser(u);
    }
  };

  const register = async (email: string, password: string) => {
    try {
      await api.post("/auth/register", { email, password });
    } catch { /* demo fallback */ }
    await login(email, password);
  };

  const logout = () => {
    localStorage.clear();
    setUser(null);
  };

  return <AuthContext.Provider value={{ user, login, register, logout }}>{children}</AuthContext.Provider>;
}

// ─── App Context ──────────────────────────────────────────────────────────────

interface AppCtx {
  goals: Goal[];
  tasks: Task[];
  selectedGoalId: number | null;
  weekStart: Date;
  setSelectedGoalId: (id: number | null) => void;
  prevWeek: () => void;
  nextWeek: () => void;
  createGoal: (d: Omit<Goal, "id">) => void;
  updateGoal: (id: number, d: Partial<Goal>) => void;
  deleteGoal: (id: number) => void;
  createTask: (d: Omit<Task, "id" | "status">) => void;
  updateTask: (id: number, d: Partial<Task>) => void;
  deleteTask: (id: number) => void;
  completeTask: (id: number, actualHours: number) => void;
  moveTask: (id: number, dueDate: string | undefined) => void;
  // modal state
  goalModal: { open: boolean; goal?: Goal };
  taskModal: { open: boolean; task?: Task; defaultGoalId?: number };
  completionModal: { open: boolean; task?: Task };
  deleteConfirm: { open: boolean; label?: string; onConfirm?: () => void };
  openGoalModal: (goal?: Goal) => void;
  closeGoalModal: () => void;
  openTaskModal: (task?: Task, defaultGoalId?: number) => void;
  closeTaskModal: () => void;
  openCompletionModal: (task: Task) => void;
  closeCompletionModal: () => void;
  openDeleteConfirm: (label: string, onConfirm: () => void) => void;
  closeDeleteConfirm: () => void;
}

const AppContext = createContext<AppCtx>(null!);
const useApp = () => useContext(AppContext);

function loadDemo<T>(key: string, seed: T): T {
  try {
    const v = localStorage.getItem(key);
    return v ? JSON.parse(v) : seed;
  } catch { return seed; }
}

function AppProvider({ children }: { children: React.ReactNode }) {
  const [goals, setGoals] = useState<Goal[]>(() => loadDemo("demo_goals", SEED_GOALS));
  const [tasks, setTasks] = useState<Task[]>(() => loadDemo("demo_tasks", SEED_TASKS));
  const [selectedGoalId, setSelectedGoalId] = useState<number | null>(null);
  const [weekStart, setWeekStart] = useState<Date>(() =>
    startOfWeek(new Date(), { weekStartsOn: 1 })
  );
  const [goalModal, setGoalModal] = useState<AppCtx["goalModal"]>({ open: false });
  const [taskModal, setTaskModal] = useState<AppCtx["taskModal"]>({ open: false });
  const [completionModal, setCompletionModal] = useState<AppCtx["completionModal"]>({ open: false });
  const [deleteConfirm, setDeleteConfirm] = useState<AppCtx["deleteConfirm"]>({ open: false });

  useEffect(() => { localStorage.setItem("demo_goals", JSON.stringify(goals)); }, [goals]);
  useEffect(() => { localStorage.setItem("demo_tasks", JSON.stringify(tasks)); }, [tasks]);

  const nextId = (arr: { id: number }[]) => Math.max(0, ...arr.map((x) => x.id)) + 1;

  const createGoal = useCallback((d: Omit<Goal, "id">) => {
    const g: Goal = { ...d, id: nextId(goals) };
    setGoals((prev) => [...prev, g]);
    api.post("/goals", d).then((r) => {
      setGoals((prev) => prev.map((x) => (x.id === g.id ? { ...r.data, color: d.color } : x)));
    }).catch(() => {});
  }, [goals]);

  const updateGoal = useCallback((id: number, d: Partial<Goal>) => {
    setGoals((prev) => prev.map((g) => (g.id === id ? { ...g, ...d } : g)));
    api.put(`/goals/${id}`, d).catch(() => {});
  }, []);

  const deleteGoal = useCallback((id: number) => {
    setGoals((prev) => prev.filter((g) => g.id !== id));
    setTasks((prev) => prev.filter((t) => t.goalId !== id));
    if (selectedGoalId === id) setSelectedGoalId(null);
    api.delete(`/goals/${id}`).catch(() => {});
  }, [selectedGoalId]);

  const createTask = useCallback((d: Omit<Task, "id" | "status">) => {
    const t: Task = { ...d, id: nextId(tasks), status: "pending" };
    setTasks((prev) => [...prev, t]);
    api.post("/tasks", d).then((r) => {
      setTasks((prev) => prev.map((x) => (x.id === t.id ? r.data : x)));
    }).catch(() => {});
  }, [tasks]);

  const updateTask = useCallback((id: number, d: Partial<Task>) => {
    setTasks((prev) => prev.map((t) => (t.id === id ? { ...t, ...d } : t)));
    api.put(`/tasks/${id}`, d).catch(() => {});
  }, []);

  const deleteTask = useCallback((id: number) => {
    setTasks((prev) => prev.filter((t) => t.id !== id));
    api.delete(`/tasks/${id}`).catch(() => {});
  }, []);

  const completeTask = useCallback((id: number, actualHours: number) => {
    setTasks((prev) => prev.map((t) => t.id === id ? { ...t, status: "done", actualHours } : t));
    api.patch(`/tasks/${id}/complete`, { actualHours }).catch(() => {});
  }, []);

  const moveTask = useCallback((id: number, dueDate: string | undefined) => {
    setTasks((prev) => prev.map((t) => t.id === id ? { ...t, dueDate } : t));
    api.patch(`/tasks/${id}`, { dueDate: dueDate ?? null }).catch(() => {});
  }, []);

  const ctx: AppCtx = {
    goals, tasks, selectedGoalId, weekStart,
    setSelectedGoalId,
    prevWeek: () => setWeekStart((d) => subWeeks(d, 1)),
    nextWeek: () => setWeekStart((d) => addWeeks(d, 1)),
    createGoal, updateGoal, deleteGoal,
    createTask, updateTask, deleteTask, completeTask, moveTask,
    goalModal, taskModal, completionModal, deleteConfirm,
    openGoalModal: (goal) => setGoalModal({ open: true, goal }),
    closeGoalModal: () => setGoalModal({ open: false }),
    openTaskModal: (task, defaultGoalId) => setTaskModal({ open: true, task, defaultGoalId }),
    closeTaskModal: () => setTaskModal({ open: false }),
    openCompletionModal: (task) => setCompletionModal({ open: true, task }),
    closeCompletionModal: () => setCompletionModal({ open: false }),
    openDeleteConfirm: (label, onConfirm) => setDeleteConfirm({ open: true, label, onConfirm }),
    closeDeleteConfirm: () => setDeleteConfirm({ open: false }),
  };

  return <AppContext.Provider value={ctx}>{children}</AppContext.Provider>;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function goalColor(goals: Goal[], goalId: number) {
  return goals.find((g) => g.id === goalId)?.color ?? "#94a3b8";
}

function hexToRgba(hex: string, alpha: number) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r},${g},${b},${alpha})`;
}

function fmtDate(dateStr?: string) {
  if (!dateStr) return null;
  const d = parseISO(dateStr);
  return isValid(d) ? format(d, "MMM d") : null;
}

// ─── Auth Page ────────────────────────────────────────────────────────────────

function AuthPage() {
  const { login, register } = useAuth();
  const navigate = useNavigate();
  const [mode, setMode] = useState<"login" | "register">("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) { setError("Please fill in all fields."); return; }
    setLoading(true); setError("");
    try {
      if (mode === "login") await login(email, password);
      else await register(email, password);
      navigate("/");
    } catch (err: any) {
      setError(err.message || "Something went wrong.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-6">
      <div className="w-full max-w-sm">
        {/* Logo */}
        <div className="mb-10 text-center">
          <div className="inline-flex items-center gap-2 mb-2">
            <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center">
              <CheckCircle2 className="w-4 h-4 text-white" />
            </div>
            <span className="text-lg font-semibold tracking-tight">Task Tracker</span>
          </div>
          <p className="text-sm text-muted-foreground">
            {mode === "login" ? "Sign in to your workspace" : "Create your workspace"}
          </p>
        </div>

        <form onSubmit={submit} className="bg-card rounded-2xl border border-border shadow-sm p-7 space-y-4">
          <div className="space-y-1.5">
            <label className="text-sm font-medium text-foreground">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@example.com"
              className="w-full h-10 px-3 rounded-xl bg-input-background border border-border text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all"
            />
          </div>
          <div className="space-y-1.5">
            <label className="text-sm font-medium text-foreground">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              className="w-full h-10 px-3 rounded-xl bg-input-background border border-border text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all"
            />
          </div>

          {error && (
            <p className="text-xs text-destructive bg-destructive/10 rounded-lg px-3 py-2">{error}</p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full h-10 bg-primary text-primary-foreground rounded-xl text-sm font-medium hover:bg-primary/90 transition-colors disabled:opacity-60 flex items-center justify-center gap-2"
          >
            {loading && <Loader2 className="w-4 h-4 animate-spin" />}
            {mode === "login" ? "Sign in" : "Create account"}
          </button>
        </form>

        <p className="mt-5 text-center text-sm text-muted-foreground">
          {mode === "login" ? "No account?" : "Already have an account?"}{" "}
          <button
            onClick={() => setMode(mode === "login" ? "register" : "login")}
            className="text-primary font-medium hover:underline"
          >
            {mode === "login" ? "Sign up" : "Sign in"}
          </button>
        </p>
      </div>
    </div>
  );
}

// ─── Protected Route ──────────────────────────────────────────────────────────

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  return user ? <>{children}</> : <Navigate to="/login" replace />;
}

// ─── Header ───────────────────────────────────────────────────────────────────

function Header() {
  const { user, logout } = useAuth();
  const { weekStart, prevWeek, nextWeek } = useApp();
  const weekEnd = addDays(weekStart, 6);

  return (
    <header className="h-14 bg-card border-b border-border flex items-center px-5 gap-4 shrink-0 z-10">
      {/* Brand */}
      <div className="flex items-center gap-2 w-64 shrink-0">
        <div className="w-6 h-6 rounded-md bg-primary flex items-center justify-center">
          <CheckCircle2 className="w-3.5 h-3.5 text-white" />
        </div>
        <span className="text-sm font-semibold tracking-tight">Task Tracker</span>
      </div>

      {/* Week navigation */}
      <div className="flex-1 flex items-center justify-center gap-3">
        <button
          onClick={prevWeek}
          className="w-7 h-7 rounded-lg hover:bg-secondary flex items-center justify-center transition-colors text-muted-foreground hover:text-foreground"
        >
          <ChevronLeft className="w-4 h-4" />
        </button>
        <span className="text-sm font-medium min-w-36 text-center">
          {format(weekStart, "MMM d")} – {format(weekEnd, "MMM d, yyyy")}
        </span>
        <button
          onClick={nextWeek}
          className="w-7 h-7 rounded-lg hover:bg-secondary flex items-center justify-center transition-colors text-muted-foreground hover:text-foreground"
        >
          <ChevronRight className="w-4 h-4" />
        </button>
      </div>

      {/* User */}
      <div className="flex items-center gap-3 w-64 justify-end">
        <div className="flex items-center gap-2">
          <div className="w-7 h-7 rounded-full bg-primary/15 flex items-center justify-center">
            <span className="text-xs font-semibold text-primary">
              {user?.email?.[0]?.toUpperCase() ?? "U"}
            </span>
          </div>
          <span className="text-xs text-muted-foreground max-w-32 truncate">{user?.email}</span>
        </div>
        <button
          onClick={logout}
          className="w-7 h-7 rounded-lg hover:bg-destructive/10 flex items-center justify-center transition-colors text-muted-foreground hover:text-destructive"
          title="Log out"
        >
          <LogOut className="w-3.5 h-3.5" />
        </button>
      </div>
    </header>
  );
}

// ─── Goal Sidebar ─────────────────────────────────────────────────────────────

function GoalSidebar() {
  const { goals, tasks, selectedGoalId, setSelectedGoalId, openGoalModal, openDeleteConfirm, deleteGoal } = useApp();

  const getCount = (goalId: number) =>
    tasks.filter((t) => t.goalId === goalId && t.status === "pending").length;

  return (
    <aside className="w-64 shrink-0 bg-sidebar border-r border-sidebar-border flex flex-col">
      <div className="px-4 pt-5 pb-3 flex items-center justify-between">
        <span className="text-xs font-semibold uppercase tracking-widest text-muted-foreground">Goals</span>
        <button
          onClick={() => openGoalModal()}
          className="w-6 h-6 rounded-md bg-primary/10 hover:bg-primary/20 flex items-center justify-center transition-colors text-primary"
          title="New goal"
        >
          <Plus className="w-3.5 h-3.5" />
        </button>
      </div>

      <nav className="flex-1 px-2 overflow-y-auto space-y-0.5">
        {/* All goals */}
        <button
          onClick={() => setSelectedGoalId(null)}
          className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-left transition-colors group ${
            selectedGoalId === null
              ? "bg-secondary text-foreground"
              : "text-muted-foreground hover:bg-secondary/60 hover:text-foreground"
          }`}
        >
          <Target className="w-3.5 h-3.5 shrink-0" />
          <span className="text-sm font-medium flex-1">All Goals</span>
          <span className="text-xs text-muted-foreground">
            {tasks.filter((t) => t.status === "pending").length}
          </span>
        </button>

        {goals.map((goal) => {
          const isActive = selectedGoalId === goal.id;
          return (
            <div key={goal.id} className="group/item relative">
              <button
                onClick={() => setSelectedGoalId(isActive ? null : goal.id)}
                className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-left transition-colors ${
                  isActive
                    ? "bg-secondary text-foreground"
                    : "text-muted-foreground hover:bg-secondary/60 hover:text-foreground"
                }`}
              >
                <span
                  className="w-2 h-2 rounded-full shrink-0"
                  style={{ backgroundColor: goal.color }}
                />
                <span className="text-sm font-medium flex-1 truncate">{goal.title}</span>
                <span className="text-xs text-muted-foreground">{getCount(goal.id)}</span>
              </button>

              {/* Actions on hover */}
              <div className="absolute right-2 top-1/2 -translate-y-1/2 hidden group-hover/item:flex items-center gap-0.5 bg-card rounded-lg shadow-sm border border-border px-1 py-0.5">
                <button
                  onClick={(e) => { e.stopPropagation(); openGoalModal(goal); }}
                  className="w-5 h-5 rounded flex items-center justify-center text-muted-foreground hover:text-foreground transition-colors"
                >
                  <Edit2 className="w-3 h-3" />
                </button>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    openDeleteConfirm(`"${goal.title}"`, () => deleteGoal(goal.id));
                  }}
                  className="w-5 h-5 rounded flex items-center justify-center text-muted-foreground hover:text-destructive transition-colors"
                >
                  <Trash2 className="w-3 h-3" />
                </button>
              </div>

              {/* Deadline */}
              {goal.deadline && (
                <div className="px-3 pb-1.5 -mt-0.5">
                  <span className={`text-xs font-mono ${
                    isPast(parseISO(goal.deadline)) ? "text-destructive" : "text-muted-foreground"
                  }`}>
                    {fmtDate(goal.deadline)}
                  </span>
                </div>
              )}
            </div>
          );
        })}
      </nav>

      <div className="p-3 border-t border-sidebar-border">
        <button
          onClick={() => openGoalModal()}
          className="w-full flex items-center gap-2 px-3 py-2 rounded-xl text-sm text-muted-foreground hover:text-foreground hover:bg-secondary/60 transition-colors"
        >
          <Plus className="w-3.5 h-3.5" />
          New goal
        </button>
      </div>
    </aside>
  );
}

// ─── Task Card (draggable) ────────────────────────────────────────────────────

function TaskCard({
  task,
  compact = false,
}: {
  task: Task;
  compact?: boolean;
}) {
  const { goals, openTaskModal, openCompletionModal, openDeleteConfirm, deleteTask, tasks } = useApp();
  const color = goalColor(goals, task.goalId);
  const goalName = goals.find((g) => g.id === task.goalId)?.title ?? "";
  const depTask = task.dependencyId ? tasks.find((t) => t.id === task.dependencyId) : undefined;

  const [{ isDragging }, dragRef] = useDrag({
    type: "TASK",
    item: { taskId: task.id },
    collect: (m) => ({ isDragging: m.isDragging() }),
  });

  return (
    <div
      ref={dragRef as any}
      style={{
        opacity: isDragging ? 0.45 : 1,
        borderLeftColor: color,
        backgroundColor: hexToRgba(color, 0.06),
      }}
      className="group relative rounded-xl border-l-[3px] border border-border bg-card px-3 py-2.5 cursor-grab active:cursor-grabbing select-none hover:shadow-sm transition-all duration-150 hover:-translate-y-px"
    >
      <div className="flex items-start gap-2">
        <button
          onClick={() => openCompletionModal(task)}
          className="mt-0.5 shrink-0 text-muted-foreground hover:text-primary transition-colors"
          title="Mark done"
        >
          <Circle className="w-3.5 h-3.5" />
        </button>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium text-foreground leading-snug truncate">{task.title}</p>
          {!compact && (
            <div className="flex items-center gap-2.5 mt-1">
              <span className="flex items-center gap-1 text-xs font-mono text-muted-foreground">
                <Clock className="w-3 h-3" />
                {task.estimatedHours}h
              </span>
              {depTask && (
                <span className="flex items-center gap-1 text-xs text-muted-foreground" title={`Depends on: ${depTask.title}`}>
                  <Link2 className="w-3 h-3" />
                  <span className="truncate max-w-20">{depTask.title}</span>
                </span>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Hover actions */}
      <div className="absolute right-2 top-2 hidden group-hover:flex items-center gap-0.5">
        <button
          onClick={() => openTaskModal(task)}
          className="w-5 h-5 rounded flex items-center justify-center text-muted-foreground hover:text-foreground transition-colors"
        >
          <Edit2 className="w-3 h-3" />
        </button>
        <button
          onClick={() => openDeleteConfirm(`"${task.title}"`, () => deleteTask(task.id))}
          className="w-5 h-5 rounded flex items-center justify-center text-muted-foreground hover:text-destructive transition-colors"
        >
          <Trash2 className="w-3 h-3" />
        </button>
      </div>
    </div>
  );
}

// ─── Day Column (droppable) ───────────────────────────────────────────────────

function DayColumn({ date, tasks }: { date: Date; tasks: Task[] }) {
  const { moveTask, openTaskModal, selectedGoalId } = useApp();
  const dateStr = format(date, "yyyy-MM-dd");
  const isToday = isSameDay(date, new Date());

  const [{ isOver }, dropRef] = useDrop<{ taskId: number }, void, { isOver: boolean }>({
    accept: "TASK",
    drop: (item) => moveTask(item.taskId, dateStr),
    collect: (m) => ({ isOver: m.isOver() }),
  });

  const dayTasks = tasks.filter((t) => t.dueDate === dateStr && t.status === "pending");

  return (
    <div
      ref={dropRef as any}
      className={`flex flex-col min-h-0 transition-colors duration-150 ${isOver ? "bg-primary/5" : ""}`}
    >
      {/* Day header */}
      <div className={`px-3 py-2.5 border-b border-border shrink-0 ${isToday ? "bg-primary/5" : ""}`}>
        <p className={`text-xs font-semibold uppercase tracking-wider ${isToday ? "text-primary" : "text-muted-foreground"}`}>
          {format(date, "EEE")}
        </p>
        <p className={`text-lg font-semibold leading-none mt-0.5 ${isToday ? "text-primary" : "text-foreground"}`}>
          {format(date, "d")}
        </p>
      </div>

      {/* Tasks */}
      <div className="flex-1 p-2 space-y-1.5 overflow-y-auto">
        {dayTasks.map((t) => (
          <TaskCard key={t.id} task={t} />
        ))}

        {/* Add task */}
        <button
          onClick={() => openTaskModal(undefined, selectedGoalId ?? undefined)}
          className="w-full flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs text-muted-foreground hover:text-foreground hover:bg-secondary/60 transition-colors opacity-0 group-hover:opacity-100"
        >
          <Plus className="w-3 h-3" />
          Add task
        </button>
      </div>
    </div>
  );
}

// ─── Weekly Calendar ──────────────────────────────────────────────────────────

function WeeklyCalendar() {
  const { weekStart, tasks, selectedGoalId } = useApp();
  const days = Array.from({ length: 7 }, (_, i) => addDays(weekStart, i));
  const visibleTasks = selectedGoalId
    ? tasks.filter((t) => t.goalId === selectedGoalId)
    : tasks;

  return (
    <div className="flex-1 flex flex-col min-h-0 overflow-hidden">
      <div className="flex-1 grid grid-cols-7 divide-x divide-border overflow-hidden group">
        {days.map((day) => (
          <DayColumn key={day.toISOString()} date={day} tasks={visibleTasks} />
        ))}
      </div>
    </div>
  );
}

// ─── Unscheduled Panel ────────────────────────────────────────────────────────

function UnscheduledPanel() {
  const { tasks, goals, selectedGoalId, openTaskModal, moveTask } = useApp();

  const [{ isOver }, dropRef] = useDrop<{ taskId: number }, void, { isOver: boolean }>({
    accept: "TASK",
    drop: (item) => moveTask(item.taskId, undefined),
    collect: (m) => ({ isOver: m.isOver() }),
  });

  const unscheduled = tasks.filter(
    (t) => !t.dueDate && t.status === "pending" && (!selectedGoalId || t.goalId === selectedGoalId)
  );

  return (
    <aside
      ref={dropRef as any}
      className={`w-60 shrink-0 border-l border-border flex flex-col transition-colors duration-150 ${isOver ? "bg-primary/5" : "bg-sidebar"}`}
    >
      <div className="px-4 pt-5 pb-3 flex items-center justify-between shrink-0">
        <div className="flex items-center gap-2">
          <Inbox className="w-3.5 h-3.5 text-muted-foreground" />
          <span className="text-xs font-semibold uppercase tracking-widest text-muted-foreground">
            Unscheduled
          </span>
        </div>
        <span className="text-xs font-mono text-muted-foreground bg-secondary rounded-md px-1.5 py-0.5">
          {unscheduled.length}
        </span>
      </div>

      <div className="flex-1 px-2 overflow-y-auto space-y-1.5 pb-4">
        {unscheduled.length === 0 && (
          <div className="flex flex-col items-center justify-center py-10 text-center px-4">
            <div className="w-8 h-8 rounded-full bg-secondary flex items-center justify-center mb-3">
              <CheckCircle2 className="w-4 h-4 text-muted-foreground" />
            </div>
            <p className="text-xs text-muted-foreground">All tasks are scheduled</p>
          </div>
        )}
        {unscheduled.map((t) => (
          <TaskCard key={t.id} task={t} compact />
        ))}
      </div>

      <div className="p-3 border-t border-sidebar-border shrink-0">
        <button
          onClick={() => openTaskModal(undefined, selectedGoalId ?? undefined)}
          className="w-full flex items-center gap-2 px-3 py-2 rounded-xl text-sm text-muted-foreground hover:text-foreground hover:bg-secondary/60 transition-colors"
        >
          <Plus className="w-3.5 h-3.5" />
          New task
        </button>
      </div>
    </aside>
  );
}

// ─── Modal base ───────────────────────────────────────────────────────────────

function ModalOverlay({
  open,
  onClose,
  title,
  children,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <Dialog.Root open={open} onOpenChange={(o) => !o && onClose()}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/30 backdrop-blur-[2px] z-40 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0" />
        <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-card rounded-2xl border border-border shadow-xl p-6 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95">
          <div className="flex items-center justify-between mb-5">
            <Dialog.Title className="text-base font-semibold text-foreground">{title}</Dialog.Title>
            <Dialog.Close className="w-7 h-7 rounded-lg hover:bg-secondary flex items-center justify-center text-muted-foreground hover:text-foreground transition-colors">
              <X className="w-4 h-4" />
            </Dialog.Close>
          </div>
          {children}
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}

function FormField({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div className="space-y-1.5">
      <label className="text-sm font-medium text-foreground">{label}</label>
      {children}
    </div>
  );
}

const inputCls =
  "w-full h-10 px-3 rounded-xl bg-input-background border border-border text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition-all";

// ─── Goal Modal ───────────────────────────────────────────────────────────────

function GoalModal() {
  const { goalModal, closeGoalModal, createGoal, updateGoal } = useApp();
  const { open, goal } = goalModal;

  const [title, setTitle] = useState("");
  const [deadline, setDeadline] = useState("");
  const [color, setColor] = useState(GOAL_COLORS[0]);

  useEffect(() => {
    if (open) {
      setTitle(goal?.title ?? "");
      setDeadline(goal?.deadline ?? "");
      setColor(goal?.color ?? GOAL_COLORS[0]);
    }
  }, [open, goal]);

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    if (goal) updateGoal(goal.id, { title: title.trim(), deadline: deadline || undefined, color });
    else createGoal({ title: title.trim(), deadline: deadline || undefined, color });
    closeGoalModal();
  };

  return (
    <ModalOverlay open={open} onClose={closeGoalModal} title={goal ? "Edit Goal" : "New Goal"}>
      <form onSubmit={submit} className="space-y-4">
        <FormField label="Title">
          <input
            autoFocus
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="e.g., Q3 Product Launch"
            className={inputCls}
          />
        </FormField>
        <FormField label="Deadline (optional)">
          <input
            type="date"
            value={deadline}
            onChange={(e) => setDeadline(e.target.value)}
            className={inputCls}
          />
        </FormField>
        <FormField label="Color">
          <div className="flex gap-2 flex-wrap">
            {GOAL_COLORS.map((c) => (
              <button
                key={c}
                type="button"
                onClick={() => setColor(c)}
                className={`w-7 h-7 rounded-lg transition-transform hover:scale-110 ${color === c ? "ring-2 ring-offset-2 ring-foreground/30 scale-110" : ""}`}
                style={{ backgroundColor: c }}
              />
            ))}
          </div>
        </FormField>
        <div className="flex gap-2 pt-1">
          <button type="button" onClick={closeGoalModal} className="flex-1 h-10 rounded-xl border border-border text-sm font-medium hover:bg-secondary transition-colors">
            Cancel
          </button>
          <button type="submit" className="flex-1 h-10 rounded-xl bg-primary text-primary-foreground text-sm font-medium hover:bg-primary/90 transition-colors">
            {goal ? "Save changes" : "Create goal"}
          </button>
        </div>
      </form>
    </ModalOverlay>
  );
}

// ─── Task Modal ───────────────────────────────────────────────────────────────

function TaskModal() {
  const { taskModal, closeTaskModal, createTask, updateTask, goals, tasks, selectedGoalId } = useApp();
  const { open, task, defaultGoalId } = taskModal;

  const [title, setTitle] = useState("");
  const [hours, setHours] = useState("1");
  const [dueDate, setDueDate] = useState("");
  const [goalId, setGoalId] = useState<number>(0);
  const [depId, setDepId] = useState<number | "">("");

  useEffect(() => {
    if (open) {
      setTitle(task?.title ?? "");
      setHours(String(task?.estimatedHours ?? 1));
      setDueDate(task?.dueDate ?? "");
      setGoalId(task?.goalId ?? defaultGoalId ?? selectedGoalId ?? (goals[0]?.id ?? 0));
      setDepId(task?.dependencyId ?? "");
    }
  }, [open, task, defaultGoalId, selectedGoalId, goals]);

  const goalTasks = tasks.filter(
    (t) => t.goalId === goalId && t.status === "pending" && t.id !== task?.id
  );

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !goalId) return;
    const payload = {
      goalId,
      title: title.trim(),
      estimatedHours: parseFloat(hours) || 1,
      dueDate: dueDate || undefined,
      dependencyId: depId !== "" ? Number(depId) : undefined,
    };
    if (task) updateTask(task.id, payload);
    else createTask(payload);
    closeTaskModal();
  };

  return (
    <ModalOverlay open={open} onClose={closeTaskModal} title={task ? "Edit Task" : "New Task"}>
      <form onSubmit={submit} className="space-y-4">
        <FormField label="Title">
          <input
            autoFocus
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="e.g., Implement auth flow"
            className={inputCls}
          />
        </FormField>

        <div className="grid grid-cols-2 gap-3">
          <FormField label="Estimated hours">
            <input
              type="number"
              min="0.5"
              step="0.5"
              value={hours}
              onChange={(e) => setHours(e.target.value)}
              className={inputCls}
            />
          </FormField>
          <FormField label="Due date (optional)">
            <input
              type="date"
              value={dueDate}
              onChange={(e) => setDueDate(e.target.value)}
              className={inputCls}
            />
          </FormField>
        </div>

        <FormField label="Goal">
          <select
            value={goalId}
            onChange={(e) => { setGoalId(Number(e.target.value)); setDepId(""); }}
            className={inputCls}
          >
            {goals.map((g) => (
              <option key={g.id} value={g.id}>{g.title}</option>
            ))}
          </select>
        </FormField>

        <FormField label="Dependency (optional)">
          <select
            value={depId}
            onChange={(e) => setDepId(e.target.value === "" ? "" : Number(e.target.value))}
            className={inputCls}
          >
            <option value="">None</option>
            {goalTasks.map((t) => (
              <option key={t.id} value={t.id}>{t.title}</option>
            ))}
          </select>
        </FormField>

        <div className="flex gap-2 pt-1">
          <button type="button" onClick={closeTaskModal} className="flex-1 h-10 rounded-xl border border-border text-sm font-medium hover:bg-secondary transition-colors">
            Cancel
          </button>
          <button type="submit" className="flex-1 h-10 rounded-xl bg-primary text-primary-foreground text-sm font-medium hover:bg-primary/90 transition-colors">
            {task ? "Save changes" : "Create task"}
          </button>
        </div>
      </form>
    </ModalOverlay>
  );
}

// ─── Completion Modal ─────────────────────────────────────────────────────────

function CompletionModal() {
  const { completionModal, closeCompletionModal, completeTask } = useApp();
  const { open, task } = completionModal;

  const [actual, setActual] = useState("1");

  useEffect(() => {
    if (open && task) setActual(String(task.estimatedHours));
  }, [open, task]);

  const confirm = () => {
    if (!task) return;
    completeTask(task.id, parseFloat(actual) || 0);
    closeCompletionModal();
  };

  return (
    <ModalOverlay open={open} onClose={closeCompletionModal} title="Mark as Done">
      {task && (
        <div className="space-y-5">
          <div className="bg-secondary rounded-xl p-4">
            <p className="text-sm font-medium text-foreground">{task.title}</p>
            <p className="text-xs text-muted-foreground mt-1">
              Estimated: {task.estimatedHours}h
            </p>
          </div>

          <FormField label="Actual hours spent">
            <input
              autoFocus
              type="number"
              min="0"
              step="0.5"
              value={actual}
              onChange={(e) => setActual(e.target.value)}
              className={inputCls}
            />
          </FormField>

          <div className="flex gap-2">
            <button onClick={closeCompletionModal} className="flex-1 h-10 rounded-xl border border-border text-sm font-medium hover:bg-secondary transition-colors">
              Cancel
            </button>
            <button
              onClick={confirm}
              className="flex-1 h-10 rounded-xl bg-primary text-primary-foreground text-sm font-medium hover:bg-primary/90 transition-colors flex items-center justify-center gap-2"
            >
              <CheckCircle2 className="w-4 h-4" />
              Mark done
            </button>
          </div>
        </div>
      )}
    </ModalOverlay>
  );
}

// ─── Delete Confirm Modal ─────────────────────────────────────────────────────

function DeleteConfirmModal() {
  const { deleteConfirm, closeDeleteConfirm } = useApp();
  const { open, label, onConfirm } = deleteConfirm;

  const confirm = () => {
    onConfirm?.();
    closeDeleteConfirm();
  };

  return (
    <ModalOverlay open={open} onClose={closeDeleteConfirm} title="Delete?">
      <div className="space-y-5">
        <p className="text-sm text-muted-foreground">
          Are you sure you want to delete {label}? This action cannot be undone.
        </p>
        <div className="flex gap-2">
          <button onClick={closeDeleteConfirm} className="flex-1 h-10 rounded-xl border border-border text-sm font-medium hover:bg-secondary transition-colors">
            Cancel
          </button>
          <button
            onClick={confirm}
            className="flex-1 h-10 rounded-xl bg-destructive text-destructive-foreground text-sm font-medium hover:bg-destructive/90 transition-colors"
          >
            Delete
          </button>
        </div>
      </div>
    </ModalOverlay>
  );
}

// ─── Main App ─────────────────────────────────────────────────────────────────

function MainApp() {
  return (
    <div className="h-screen flex flex-col overflow-hidden bg-background">
      <Header />
      <div className="flex flex-1 min-h-0 overflow-hidden">
        <GoalSidebar />
        <WeeklyCalendar />
        <UnscheduledPanel />
      </div>
      <GoalModal />
      <TaskModal />
      <CompletionModal />
      <DeleteConfirmModal />
    </div>
  );
}

// ─── Root ─────────────────────────────────────────────────────────────────────

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <DndProvider backend={HTML5Backend}>
          <AppProvider>
            <Routes>
              <Route path="/login" element={<AuthPage />} />
              <Route
                path="/"
                element={
                  <ProtectedRoute>
                    <MainApp />
                  </ProtectedRoute>
                }
              />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </AppProvider>
        </DndProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}
