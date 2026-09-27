# Visual Language & Design System

## Art Direction

> Todow is a warm light task canvas. A clean cream background floats solid white cards with soft shadows. Action is driven by Azure; attention is driven by Amber. Gradients are strictly prohibited. The corner arc decor uses specific solid colors layered over the background.

This sentence is the app's visual contract. Every screen must be auditable against it.

### Decor System — Concentric Corner Wedge Arcs

Three concentric arc wedges, **solid fills, no gradient**, anchored to:
- **Task editor**: top-left corner
- **Home screen**: top-right corner (mirrored)

**Drawn with `CustomPaint` using `canvas.drawArc(rect, startAngle, sweepAngle, true, paint)` (`useCenter: true`).**

**Wedge specifications (task editor, top-left anchor):**

| Layer | Radius | Fill |
|---|---|---|
| Outer (back) | 200dp | Surface Elevated (#FAF7F2) |
| Middle | 135dp | Computed Pink (#F5BED5) |
| Inner (front) | 60dp | Decor Coral (#FB7185) |

All three are centered at `Offset(0, 0)`, sweep angle 90° (π/2 radians), start angle 0 (pointing right). No stroke, no shadow, no gradient.

**Home screen variant:** same radii (200, 135, 75), centered at `Offset(screenWidth, 0)`, sweep start angle π (pointing left), centered at top-right.

**Hard rules:**
- No radial or linear gradients anywhere in the presentation layer.
- Corner decor uses only the specified solid fills.

### Four-Plane Hierarchy

Every screen must stack these four planes in order (back to front):

| Plane | Element | Token |
|---|---|---|
| 1 | App scaffold | `AppColors.background` |
| 2 | Corner arc decor | Surface Elevated / Computed Pink / Decor Coral |
| 3 | Content surface blocks | `AppColors.surface` |
| 4 | Primary action (CTA) | `AppColors.action` |

### Floating Shadow Rule

Cards and blocks float above the cream background using a single, unified soft shadow:
`BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))`
Applied to: hero card, secondary cards, task rows block, quick add, nav pill.

## Core Vibe
- **Calm, focused, serious, technical, student-first.**
- Designed for daytime studying. Light and airy.
- **Aesthetics to avoid**: Dark mode tropes, glassmorphism, neon effects, excessive shadows, rainbow colors, generic illustrations, gamification, AI buzzwords.

## Typography Scale
- **Display**: ~28-34px, Extra Bold (Page titles).
- **Heading**: ~20-24px, Bold (Secondary cards, major categories).
- **Body / Action**: ~15-17px, Medium/Bold (Task titles, buttons).
- **Caption / Overline**: ~13-14px, Bold, uppercase tracking (Section headers).

## Color Palette Constraints

| Role | Hex | Use |
|---|---|---|
| Background | #F5F1EA | Warm cream canvas |
| Surface | #FFFFFF | Cards, rows |
| Surface Elevated | #FAF7F2 | Grouped blocks inside cards, outer arc wedge |
| Text Primary | #1A1D24 | Titles, inputs |
| Text Secondary | #78716C | Labels, metadata |
| Action | #0EA5E9 | Primary buttons, selected pills, links |
| Attention | #F59E0B | Progress bars, destructive actions |
| Alert | #EF4444 | Overdue, destructive only |
| Divider | #E8E3DA | Recessed carve inside grouped blocks |
| Decor Pink | #F472B6 | Roadmap pill cycle, mid arc wedge |
| Decor Coral | #FB7185 | Roadmap pill cycle, inner arc wedge |
| Decor Navy | #1E3A8A | Roadmap pill cycle |

## Accent Contract

- Solid Azure #0EA5E9 = actions (buttons, links, selected pills)
- Solid Amber #F59E0B = attention (progress bars, streaks)
- Cycle Navy → Pink → Coral = roadmap pills, corner decor accents

Never mix. Gradients are prohibited. An amber button is a bug. A gradient on any element is a bug.

## Component Patterns

### Home Screen
- **Hero Card**: White surface, soft shadow. Category chip top-right (Navy). Amber progress bar.
- **Secondary Cards**: White surface, soft shadow. Category chip top-right (Pink/Coral/Navy cycle). Amber progress bar.
- **Task Rows**: All tasks inside a single white surface block with soft shadow and 1px divider between rows.
- **Quick Add**: White surface, soft shadow, borderless text field.

### Task Editor
- **Header**: "New task" 34/w800/-0.8/textPrimary + Amber underline.
- **WHEN Row**: Compact pills. Selected = solid action + white text. Unselected = transparent + 1px border. Icon buttons = white surface + 1px border.
- **PROJECTS Row**: Compact pills. Selected = solid cycle color (Navy/Pink/Coral) + white text. Unselected = transparent + 1px border.
- **TASK Fields**: Single white surface block with 1px divider.

## FR-01.v2 Task Dependency Graph

FR-01.v2 adds three physical interaction patterns to the active task list: drag-to-reorder, swipe-to-complete/delete, and double-tap inline insert. All three are coordinated through domain methods that operate purely on `sortOrder` integers and `TaskStatus` transitions. No new data types or network calls are introduced. The UI layer is additive — `ReorderableListView`, `Slidable`, and a `GestureDetector.onDoubleTap` wrapper slot onto the existing task row without changing its visual recipe. Persistence is guaranteed because `reorderTask` writes each affected row's `sort_order` back to SQLite before reloading state.

### Requirements Table

| Feature | Assertion that proves it |
|---|---|
| Drag reorder | `reorderTask(0, 2)` on [A,B,C] → activeTasks[0].title == 'Task B' |
| Insert below | `insertTaskBelow(taskA.id, 'B')` on [A,C] → activeTasks[1].title == 'Task B' |
| Swipe complete | `completeTask(id)` → `activeTasks.length == 0`, `tasks.first.status == completed` |
| Swipe delete | `deleteTask(id)` → `tasks.length == 0` |
| No-op safety | `completeTask` on missing id returns silently; `deleteTask` on missing id returns silently |
| sortOrder persistence | `sort_order` column in `tasks` table, read/written by repository |

### Task Dependency Graph (ordered)

```
1. Task.sortOrder (field, default 0) ─────────────────────┐
2. DB migration: sort_order column ──────────────────────┐ │
3. TaskRepository.getAll() reads sort_order ─────────── │ │
4. TaskController.reorderTask(old, new) ─────────────── ▼ ▼
5. TaskController.insertTaskBelow(id, title) ──────────── 4
6. TaskController.completeTask(id) — already existed ─────┐
7. TaskController.deleteTask(id) — already existed ────────┘
8. Tests: task_reorder_test, task_insert_test, task_swipe_test ← 4,5,6,7
9. UI: ReorderableListView.builder wraps active list ──── ← 4
10. UI: Slidable wraps each task row ──────────────────── ← 6,7
11. UI: GestureDetector.onDoubleTap on row ─────────────── ← 5
```

---

## Component Recipes

Extracted from live code. Every value is quoted from source.

### Task Row
| Property | Value | Source |
|---|---|---|
| Height | `68` | [`home_screen.dart:448`](file:///d:/Ahmad/p1ng-todo-manager/lib/presentation/screens/home_screen.dart#L448) |
| H-padding | `16` px | [`home_screen.dart:449`](file:///d:/Ahmad/p1ng-todo-manager/lib/presentation/screens/home_screen.dart#L449) |
| Background | `AppColors.surface` (#FFFFFF) | grouped container |
| Divider | `AppColors.divider` (#E8E3DA), 1px, omitted on last row | [`home_screen.dart:452`](file:///d:/Ahmad/p1ng-todo-manager/lib/presentation/screens/home_screen.dart#L452) |
| Circle toggle size | `22×22` | [`home_screen.dart:461`](file:///d:/Ahmad/p1ng-todo-manager/lib/presentation/screens/home_screen.dart#L461) |
| Title style | `fontSize:15, fontWeight:w600, color:textPrimary` | [`home_screen.dart:476`](file:///d:/Ahmad/p1ng-todo-manager/lib/presentation/screens/home_screen.dart#L476) |
| Metadata style | `fontSize:12, fontWeight:w500, color:textSecondaryOpacity(0.7)` | [`home_screen.dart:487`](file:///d:/Ahmad/p1ng-todo-manager/lib/presentation/screens/home_screen.dart#L487) |
| Drag handle icon | `Icons.drag_indicator, size:20` | [`home_screen.dart:506`](file:///d:/Ahmad/p1ng-todo-manager/lib/presentation/screens/home_screen.dart#L506) |

### Grouped Block (task list container)
| Property | Value | Source |
|---|---|---|
| Radius | `14` dp | [`home_screen.dart:143`](file:///d:/Ahmad/p1ng-todo-manager/lib/presentation/screens/home_screen.dart#L143) |
| Shadow | `BoxShadow(Color(0x0F000000), blurRadius:8, offset:Offset(0,2))` | [`home_screen.dart:13`](file:///d:/Ahmad/p1ng-todo-manager/lib/presentation/screens/home_screen.dart#L13) |
| H-padding (outer) | `24` px symmetric | [`home_screen.dart:139`](file:///d:/Ahmad/p1ng-todo-manager/lib/presentation/screens/home_screen.dart#L139) |
| Divider color | `AppColors.divider` | above |

### Card (Hero / Secondary)
| Property | Value | Source |
|---|---|---|
| Radius | `20` dp | hero card `BorderRadius.circular(20)` |
| Shadow | same soft shadow as grouped block | `_softShadow` constant |
| Background | `AppColors.surface` | |

### Action Pane (new recipe — Swipe Actions)
Swipe actions have no prior recipe in this codebase. Defined here as the canonical spec.

| Property | Value | Justification |
|---|---|---|
| Complete bg | `AppColors.attention` (#F59E0B) | Amber = attention token, matches accent contract |
| Delete bg | `AppColors.alert` (#EF4444) | Alert = destructive-only token |
| Icon color | `Colors.white` | Maximum contrast on colored bg |
| Icons | `Icons.check_rounded` (complete), `Icons.delete_outline_rounded` (delete) | Already used in existing slidable actions |
| Motion | `ScrollMotion()` | Minimal, no bounciness — matches calm vibe |

