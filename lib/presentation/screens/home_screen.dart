import 'package:flutter/material.dart';
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

const _softShadow = BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2));

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your\nProjects (3)',
                          style: TextStyle(fontSize: 34, height: 1.1, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1),
                        ).animate().fadeIn().slideY(begin: 0.2),
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
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [_softShadow],
                        ),
                        child: ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: active.length,
                          onReorder: tc.reorderTask,
                          itemBuilder: (_, i) => Padding(
                            key: ValueKey(active[i].id),
                            padding: EdgeInsets.zero,
                            child: _TaskRow(task: active[i], controller: tc, isFirst: i == 0, isLast: i == active.length - 1)
                              .animate(delay: Duration(milliseconds: 460 + i * 55))
                              .fadeIn(duration: 280.ms)
                              .slideY(begin: 0.12, curve: Curves.easeOutCubic),
                          ),
                        ),
                      ).animate().fadeIn(delay: 450.ms),
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
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [_softShadow],
                              ),
                              child: Column(
                                children: [
                                  for (int i = 0; i < done.length; i++)
                                    _TaskRow(task: done[i], controller: tc, isFirst: i == 0, isLast: i == done.length - 1),
                                ],
                              ),
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
  const _TaskRow({required this.task, required this.controller, this.isFirst = false, this.isLast = false});
  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskEditorScreen(task: widget.task)));
      },
      onTapCancel: () => setState(() => _pressed = false),
      onDoubleTap: () => widget.controller.insertTaskBelow(widget.task.id, 'New Task'),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Slidable(
        key: ValueKey(widget.task.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => widget.task.isCompleted ? widget.controller.reopenTask(widget.task.id) : widget.controller.completeTask(widget.task.id),
              backgroundColor: widget.task.isCompleted ? AppColors.surfaceElevated : AppColors.action,
              foregroundColor: widget.task.isCompleted ? AppColors.textPrimary : Colors.white,
              icon: widget.task.isCompleted ? Icons.undo : Icons.check_rounded,
            ),
            SlidableAction(
              onPressed: (_) => widget.controller.deleteTask(widget.task.id),
              backgroundColor: AppColors.alert,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline_rounded,
            ),
          ],
        ),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: widget.isLast ? BorderSide.none : const BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => widget.task.isCompleted ? widget.controller.reopenTask(widget.task.id) : widget.controller.completeTask(widget.task.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.task.isCompleted ? AppColors.attention : Colors.transparent,
                    border: Border.all(color: widget.task.isCompleted ? AppColors.attention : AppColors.textSecondaryOpacity(0.6), width: 1.5),
                  ),
                  child: widget.task.isCompleted ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
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
              Icon(Icons.drag_indicator, size: 20, color: AppColors.textSecondaryOpacity(0.5)),
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
