import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/models/roadmap.dart';
import 'package:todow/presentation/controllers/task_controller.dart';
import 'package:todow/presentation/screens/roadmap_detail_screen.dart';
import 'package:todow/presentation/screens/task_editor_screen.dart';
import 'package:todow/presentation/widgets/corner_arc_decor.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _softShadow = BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2));

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _insertingBelowId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskController>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.watch<TaskController>();
    final active = tc.activeTasks;
    final done = tc.tasks.where((t) => t.isCompleted).toList();
    final total = tc.tasks.length;

    final primary = Roadmap(
      id: '1',
      title: 'Master Roadmap',
      description: 'Your main goals for this semester.',
      completedTasks: done.length,
      totalTasks: total == 0 ? 1 : total,
      gradient: const [Colors.transparent, Colors.transparent],
    );
    const secondaries = [
      Roadmap(id: '2', title: 'Daily Tasks', description: '', completedTasks: 2, totalTasks: 4, gradient: [Colors.transparent, Colors.transparent]),
      Roadmap(id: '3', title: 'Business', description: '', completedTasks: 40, totalTasks: 40, gradient: [Colors.transparent, Colors.transparent]),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const CornerArcDecor(corner: Alignment.topRight, scale: 1.2),
          SafeArea(
            bottom: false,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: () {
                if (active.isNotEmpty) {
                  setState(() => _insertingBelowId = active.last.id);
                } else {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaskEditorScreen()));
                }
              },
              child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FutureBuilder<SharedPreferences>(
                          future: SharedPreferences.getInstance(),
                          builder: (context, snapshot) {
                            final name = snapshot.data?.getString('username');
                            
                            String timeGreeting = 'Good evening';
                            final hour = DateTime.now().hour;
                            if (hour < 12) {
                              timeGreeting = 'Good morning';
                            } else if (hour < 17) {
                              timeGreeting = 'Good afternoon';
                            }
                            
                            final greeting = name != null && name.isNotEmpty ? '$timeGreeting,\n$name' : 'Your\nProjects (3)';
                            return Text(
                              greeting,
                              style: const TextStyle(fontSize: 34, height: 1.1, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1),
                            ).animate().fadeIn().slideY(begin: 0.2);
                          }
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _HeroCard(roadmap: primary).animate().fadeIn(delay: 150.ms).slideY(begin: 0.08),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 160,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: secondaries.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                      const secondaryGradients = [
                          LinearGradient(colors: [AppColors.action, Color(0xFF0284C7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          LinearGradient(colors: [AppColors.decorPink, AppColors.decorCoral], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          LinearGradient(colors: [AppColors.attention, AppColors.decorCoral], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        ];
                        return _SecondaryCard(
                          roadmap: secondaries[i],
                          gradient: secondaryGradients[i % secondaryGradients.length],
                        ).animate().fadeIn(delay: Duration(milliseconds: 250 + i * 80)).slideX(begin: 0.06, curve: Curves.easeOutExpo);
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 36)),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TODAY\'S TASKS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary)),
                        Text('${active.length} tasks', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryOpacity(0.5))),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ),

                if (tc.loading)
                  const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: AppColors.action, strokeWidth: 2)))),

                if (!tc.loading && active.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      child: _EmptyTasksHint(onAdd: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaskEditorScreen())))
                        .animate().fadeIn(delay: 350.ms, duration: 400.ms).scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOutBack),
                    ),
                  ),

                if (!tc.loading && active.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: active.length,
                        onReorder: tc.reorderTask,
                        proxyDecorator: (child, index, animation) => Material(color: Colors.transparent, elevation: 0, child: child),
                        itemBuilder: (_, i) => GestureDetector(
                          key: ValueKey(active[i].id),
                          behavior: HitTestBehavior.translucent,
                          onDoubleTap: () {
                            setState(() => _insertingBelowId = active[i].id);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ReorderableDelayedDragStartListener(
                              index: i,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _TaskRow(
                                    task: active[i], 
                                    controller: tc, 
                                    index: i,
                                    isFirst: i == 0, 
                                    isLast: i == active.length - 1 && _insertingBelowId != active[i].id,
                                    onInsertRequested: () {
                                      setState(() => _insertingBelowId = active[i].id);
                                    }
                                  )
                                    .animate(delay: Duration(milliseconds: 460 + i * 55))
                                    .fadeIn(duration: 280.ms)
                                    .slideY(begin: 0.12, curve: Curves.easeOutCubic),
                                  if (_insertingBelowId == active[i].id)
                                    _InlineInsertField(
                                      aboveId: active[i].id,
                                      controller: tc,
                                      onDismissed: () => setState(() => _insertingBelowId = null),
                                      isLast: i == active.length - 1,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: _QuickAdd(controller: tc)
                      .animate().fadeIn(delay: 750.ms).slideY(begin: 0.3, curve: Curves.easeOutBack),
                  ),
                ),

                if (!tc.loading && done.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('DONE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary)),
                          children: [
                            Column(
                              children: [
                                for (int i = 0; i < done.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _TaskRow(task: done[i], controller: tc, index: -1, isFirst: i == 0, isLast: i == done.length - 1),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),

          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [_softShadow],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _NavIcon(Icons.grid_view_rounded, true),
                      const SizedBox(width: 28),
                      const _NavIcon(Icons.check_circle_outline_rounded, false),
                      const SizedBox(width: 28),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaskEditorScreen())),
                        child: Container(
                          width: 48, height: 48,
                          decoration: const BoxDecoration(color: AppColors.action, shape: BoxShape.circle),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                        ),
                      ),
                      const SizedBox(width: 28),
                      const _NavIcon(Icons.calendar_today_outlined, false),
                      const SizedBox(width: 28),
                      const _NavIcon(Icons.person_outline_rounded, false),
                    ],
                  ),
                ).animate().slideY(begin: 1.5, curve: Curves.easeOutBack, duration: 800.ms, delay: 500.ms),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────── HERO CARD ────────────────────────────────

class _HeroCard extends StatefulWidget {
  final Roadmap roadmap;
  const _HeroCard({required this.roadmap});
  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final progress = widget.roadmap.completedTasks / (widget.roadmap.totalTasks == 0 ? 1 : widget.roadmap.totalTasks);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoadmapDetailScreen(roadmap: widget.roadmap)));
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutExpo,
        child: Hero(
          tag: 'roadmap_${widget.roadmap.id}',
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              height: 120,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFFF59E0B)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [_softShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.roadmap.title, 
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Roadmap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${widget.roadmap.completedTasks}/${widget.roadmap.totalTasks} tasks', 
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────── SECONDARY CARD ──────────────────────────────

class _SecondaryCard extends StatelessWidget {
  final Roadmap roadmap;
  final Gradient gradient;
  const _SecondaryCard({required this.roadmap, required this.gradient});

  @override
  Widget build(BuildContext context) {
    final progress = roadmap.completedTasks / (roadmap.totalTasks == 0 ? 1 : roadmap.totalTasks);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoadmapDetailScreen(roadmap: roadmap))),
      child: Hero(
        tag: 'roadmap_${roadmap.id}',
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [_softShadow],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Roadmap', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70)),
                    ],
                  ),
                  const Spacer(),
                  Text(roadmap.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text('${roadmap.completedTasks}/${roadmap.totalTasks} tasks', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────── TASK ROW ───────────────────────────────────

class _TaskRow extends StatefulWidget {
  final Task task;
  final TaskController controller;
  final bool isFirst;
  final bool isLast;
  final int index;
  final VoidCallback? onInsertRequested;
  const _TaskRow({required this.task, required this.controller, required this.index, this.isFirst = false, this.isLast = false, this.onInsertRequested});
  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskEditorScreen(task: widget.task)));
      },
      onDoubleTap: () {
        setState(() => _pressed = false);
        widget.onInsertRequested?.call();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Slidable(
        key: ValueKey(widget.task.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: widget.task.isCompleted ? 0.48 : 0.24,
          children: [
            if (widget.task.isCompleted) ...[
              CustomSlidableAction(
                onPressed: (_) => widget.controller.reopenTask(widget.task.id),
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.only(left: 8, right: 4),
                child: _SwipeActionTile(
                  icon: Icons.replay_rounded,
                  label: 'Undo',
                  color: AppColors.action,
                ),
              ),
              CustomSlidableAction(
                onPressed: (_) => widget.controller.deleteTask(widget.task.id),
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: _SwipeActionTile(
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                  color: AppColors.alert,
                ),
              ),
            ] else
              CustomSlidableAction(
                onPressed: (_) => widget.controller.completeTask(widget.task.id),
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _SwipeActionTile(
                  icon: Icons.check_rounded,
                  label: 'Done',
                  color: const Color(0xFF22C55E),
                ),
              ),
          ],
        ),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [_softShadow],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.task.isCompleted
                      ? AppColors.textSecondaryOpacity(0.2)
                      : AppColors.action,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: widget.task.isCompleted ? AppColors.textSecondaryOpacity(0.5) : AppColors.textPrimary,
                      decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textSecondaryOpacity(0.3),
                    )),
                    if (widget.task.dueAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _formatTime(widget.task.dueAt!),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondaryOpacity(0.7)),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.task.category != null && widget.task.category!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(widget.task.category!).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.task.category!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _getCategoryColor(widget.task.category!)),
                  ),
                ),
              const SizedBox(width: 16),
              if (widget.index >= 0)
                ReorderableDragStartListener(
                  index: widget.index,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Icon(Icons.drag_indicator, size: 20, color: AppColors.textSecondaryOpacity(0.5)),
                    ),
                  ),
                )
              else
                Icon(Icons.drag_indicator, size: 20, color: AppColors.textSecondaryOpacity(0.3)),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('academic') || cat.contains('study')) return AppColors.decorNavy;
    if (cat.contains('health') || cat.contains('gym')) return AppColors.decorCoral;
    if (cat.contains('personal')) return AppColors.decorPink;
    return AppColors.action;
  }

  String _formatTime(DateTime d) {
    final hr = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final min = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${hr.toString().padLeft(2, '0')}:$min $ampm';
  }
}

// ────────────────────────────── QUICK ADD ────────────────────────────────────

class _QuickAdd extends StatefulWidget {
  final TaskController controller;
  const _QuickAdd({required this.controller});
  @override
  State<_QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<_QuickAdd> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() { _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaskEditorScreen()));
    } else {
      widget.controller.createTask(title: text, category: 'Master Roadmap');
      _ctrl.clear();
      _focus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [_softShadow],
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            onSubmitted: (_) => _submit(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Quick Add...',
              hintStyle: TextStyle(fontSize: 15, color: AppColors.textSecondaryOpacity(0.6)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        GestureDetector(
          onTap: _submit,
          child: Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: AppColors.action, shape: BoxShape.circle),
            child: const Icon(Icons.add_rounded, size: 24, color: AppColors.surface),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────── EMPTY STATE ─────────────────────────────────

class _EmptyTasksHint extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyTasksHint({required this.onAdd});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onAdd,
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_softShadow],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text('No tasks today', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          const Text('Tap to add your first task', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    ),
  );
}

// ──────────────────────────────── NAV ICON ───────────────────────────────────

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  const _NavIcon(this.icon, this.selected);
  @override
  Widget build(BuildContext context) => Icon(icon, size: 24, color: selected ? AppColors.textPrimary : AppColors.textSecondary);
}

// ─────────────────────────── SWIPE ACTION TILE ───────────────────────────────

class _SwipeActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SwipeActionTile({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
      ],
    ),
  );
}

// ────────────────────────────── INLINE INSERT ──────────────────────────────────

class _InlineInsertField extends StatefulWidget {
  final String aboveId;
  final TaskController controller;
  final VoidCallback onDismissed;
  final bool isLast;

  const _InlineInsertField({
    required this.aboveId,
    required this.controller,
    required this.onDismissed,
    this.isLast = false,
  });

  @override
  State<_InlineInsertField> createState() => _InlineInsertFieldState();
}

class _InlineInsertFieldState extends State<_InlineInsertField> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focus.hasFocus) {
      _submit();
    }
  }

  void _submit() {
    if (_submitted) return;
    _submitted = true;
    final text = _ctrl.text.trim();
    if (text.isNotEmpty) {
      widget.controller.insertTaskBelow(widget.aboveId, text);
    }
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          _submitted = true;
          _ctrl.clear();
          widget.onDismissed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        height: 72,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.action.withValues(alpha: 0.6), width: 1.5),
          boxShadow: const [_softShadow],
        ),
        child: Row(
          children: [
            Container(
              width: 22, height: 22,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 2),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'New task...',
                  hintStyle: TextStyle(fontSize: 15, color: AppColors.textSecondaryOpacity(0.6)),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_rounded, color: AppColors.action, size: 20),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
