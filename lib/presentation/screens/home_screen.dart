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
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/query.dart';
import 'package:todow/domain/date_labels.dart';
const _softShadow = BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2));

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _insertingBelowId;
  Map<String, int> _attachmentCounts = {};
  bool _isFilterExpanded = false;
  final _searchCtrl = TextEditingController();
  String? _username;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tc = context.read<TaskController>();
      await tc.loadTasks();
      final ids = tc.tasks.map((t) => t.id).toList();
      final counts = await tc.attachmentCounts(ids);
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _attachmentCounts = counts;
          _username = prefs.getString('username');
        });
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool filterIsActive(TaskFilter f) => f.status != TaskStatusFilter.open || f.priorities.isNotEmpty || f.due.isNotEmpty;

  String sortLabel(TaskSort s) {
    switch(s) {
      case TaskSort.manual: return 'Manual Order';
      case TaskSort.dueDateAsc: return 'Due Date (Earliest)';
      case TaskSort.dueDateDesc: return 'Due Date (Latest)';
      case TaskSort.priorityDesc: return 'Priority';
      case TaskSort.createdDesc: return 'Newest First';
      case TaskSort.titleAsc: return 'Title (A–Z)';
    }
  }

  void _showSortSheet(BuildContext context, TaskController tc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Text('Sort by', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 4),
                ...TaskSort.values.where((s) => s != TaskSort.manual).map((s) {
                  final selected = tc.sort == s;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    title: Text(sortLabel(s), style: TextStyle(fontSize: 15, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.action : AppColors.textPrimary)),
                    trailing: selected ? const Icon(Icons.check_rounded, color: AppColors.action, size: 18) : null,
                    onTap: () { tc.setSort(s); Navigator.pop(context); },
                  );
                }),
                if (tc.sort != TaskSort.manual) ...[
                  const Divider(indent: 24, endIndent: 24, height: 24),
                  GestureDetector(
                    onTap: () { tc.setSort(TaskSort.manual); Navigator.pop(context); },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text('Clear sort', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskListItem(TaskController tc, List<Task> active, int i, bool isReorderable) {
    final taskRow = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TaskRow(
          task: active[i], 
          controller: tc, 
          index: i,
          attachmentCount: _attachmentCounts[active[i].id] ?? 0,
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
    );

    return GestureDetector(
      key: ValueKey(active[i].id),
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () {
        setState(() => _insertingBelowId = active[i].id);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: isReorderable
            ? ReorderableDelayedDragStartListener(
                index: i,
                child: taskRow,
              )
            : taskRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.watch<TaskController>();
    final visibleTasks = tc.visibleTasks;
    final active = visibleTasks.where((t) => t.status == TaskStatus.active).toList();
    final allCompleted = applyQuery(tc.tasks, SearchQuery(text: tc.query, filter: tc.filter.copyWith(status: TaskStatusFilter.completed), sort: tc.sort));
    final done = allCompleted;

    final Map<String, List<Task>> grouped = {};
    for (final task in visibleTasks) {
      final cat = (task.category != null && task.category!.isNotEmpty) ? task.category! : 'Inbox';
      grouped.putIfAbsent(cat, () => []).add(task);
    }

    final roadmaps = grouped.entries.map((e) {
      final title = e.key;
      final total = e.value.length;
      final completed = e.value.where((t) => t.isCompleted).length;
      return Roadmap(
        id: title,
        title: title,
        description: '',
        completedTasks: completed,
        totalTasks: total, // allows 0/0 to display naturally
        gradient: const [Colors.transparent, Colors.transparent],
      );
    }).toList();

    roadmaps.sort((a, b) => b.totalTasks.compareTo(a.totalTasks));

    // Pad with defaults if fewer than 3 to keep the three tiles prominent
    // In the future, this can be pulled from user settings to select their fav 3 tiles
    final defaults = ['Master Roadmap', 'Daily Tasks', 'Personal Notes'];
    for (final def in defaults) {
      if (roadmaps.length >= 3) break;
      if (!roadmaps.any((r) => r.title == def)) {
        roadmaps.add(Roadmap(id: def, title: def, description: '', completedTasks: 0, totalTasks: 0, gradient: const [Colors.transparent, Colors.transparent]));
      }
    }

    final primary = roadmaps.first;
    final secondaries = roadmaps.skip(1).toList();

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
                    child: Text(
                      () {
                        final hour = DateTime.now().hour;
                        final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
                        return (_username != null && _username!.isNotEmpty)
                            ? '$greeting,\n$_username'
                            : 'Your\nProjects (${roadmaps.length})';
                      }(),
                      style: const TextStyle(fontSize: 34, height: 1.1, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1),
                    ).animate().fadeIn().slideY(begin: 0.2),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: tc.setQuery,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Search tasks...',
                                hintStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textSecondaryOpacity(0.6)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (tc.query.isNotEmpty)
                            GestureDetector(
                              onTap: () { _searchCtrl.clear(); tc.clearQuery(); },
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                              ),
                            ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 8, 12),
                    child: Row(
                      children: [
                        const Expanded(child: Text('TASKS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary))),
                        IconButton(
                          icon: Icon(Icons.filter_list, size: 20, color: _isFilterExpanded || filterIsActive(tc.filter) ? AppColors.action : AppColors.textSecondary),
                          onPressed: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
                        ),
                        IconButton(
                          icon: Icon(Icons.sort, size: 20, color: tc.sort != TaskSort.manual ? AppColors.action : AppColors.textSecondary),
                          onPressed: () => _showSortSheet(context, tc),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ),

                if (_isFilterExpanded)
                  SliverToBoxAdapter(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        children: [
                          _FilterChip(
                            label: 'Open',
                            selected: tc.filter.status == TaskStatusFilter.open,
                            onTap: () => tc.setFilter(tc.filter.copyWith(status: tc.filter.status == TaskStatusFilter.open ? TaskStatusFilter.all : TaskStatusFilter.open)),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Completed',
                            selected: tc.filter.status == TaskStatusFilter.completed,
                            onTap: () => tc.setFilter(tc.filter.copyWith(status: tc.filter.status == TaskStatusFilter.completed ? TaskStatusFilter.all : TaskStatusFilter.completed)),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'High Priority',
                            selected: tc.filter.priorities.contains(TaskPriority.high),
                            onTap: () {
                              final p = Set.of(tc.filter.priorities);
                              p.contains(TaskPriority.high) ? p.remove(TaskPriority.high) : p.add(TaskPriority.high);
                              tc.setFilter(tc.filter.copyWith(priorities: p));
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Overdue',
                            selected: tc.filter.due.contains(DueFilter.overdue),
                            onTap: () {
                              final d = Set.of(tc.filter.due);
                              d.contains(DueFilter.overdue) ? d.remove(DueFilter.overdue) : d.add(DueFilter.overdue);
                              tc.setFilter(tc.filter.copyWith(due: d));
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Today',
                            selected: tc.filter.due.contains(DueFilter.today),
                            onTap: () {
                              final d = Set.of(tc.filter.due);
                              d.contains(DueFilter.today) ? d.remove(DueFilter.today) : d.add(DueFilter.today);
                              tc.setFilter(tc.filter.copyWith(due: d));
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'This Week',
                            selected: tc.filter.due.contains(DueFilter.thisWeek),
                            onTap: () {
                              final d = Set.of(tc.filter.due);
                              d.contains(DueFilter.thisWeek) ? d.remove(DueFilter.thisWeek) : d.add(DueFilter.thisWeek);
                              tc.setFilter(tc.filter.copyWith(due: d));
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'No Date',
                            selected: tc.filter.due.contains(DueFilter.noDate),
                            onTap: () {
                              final d = Set.of(tc.filter.due);
                              d.contains(DueFilter.noDate) ? d.remove(DueFilter.noDate) : d.add(DueFilter.noDate);
                              tc.setFilter(tc.filter.copyWith(due: d));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_isFilterExpanded)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(padding: const EdgeInsets.all(8)),
                            onPressed: () {
                              tc.setFilter(TaskFilter.empty());
                            },
                            child: const Text('Clear filters', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.action)),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (tc.loading)
                  const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: AppColors.action, strokeWidth: 2)))),

                if (!tc.loading && active.isEmpty && (tc.query.isNotEmpty || filterIsActive(tc.filter)))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          const Text('No tasks match', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: tc.clearQuery,
                            child: const Text('Clear all filters', style: TextStyle(color: AppColors.action)),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (!tc.loading && active.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      child: _EmptyTasksHint(onAdd: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaskEditorScreen())))
                        .animate().fadeIn(delay: 350.ms, duration: 400.ms).scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOutBack),
                    ),
                  ),

                if (!tc.loading && active.isNotEmpty)
                  if (tc.sort != TaskSort.manual)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                        child: Text('Sorted by ${sortLabel(tc.sort)}. Drag is disabled.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOpacity(0.7))),
                      ),
                    ),
                    
                if (!tc.loading && active.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: tc.sort == TaskSort.manual
                        ? SliverReorderableList(
                            itemCount: active.length,
                            onReorder: tc.reorderTask,
                            proxyDecorator: (child, index, animation) => Material(color: Colors.transparent, elevation: 0, child: child),
                            itemBuilder: (_, i) => _buildTaskListItem(tc, active, i, true),
                          )
                        : SliverList.builder(
                            itemCount: active.length,
                            itemBuilder: (_, i) => _buildTaskListItem(tc, active, i, false),
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
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: false,
                          tilePadding: EdgeInsets.zero,
                          title: Text('Completed (${done.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          iconColor: AppColors.textSecondary,
                          collapsedIconColor: AppColors.textSecondaryOpacity(0.5),
                          children: [
                            const SizedBox(height: 12),
                            Column(
                              children: [
                                for (int i = 0; i < done.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Opacity(
                                      opacity: 0.65,
                                      child: _TaskRow(
                                        task: done[i], 
                                        controller: tc, 
                                        index: -1, 
                                        attachmentCount: _attachmentCounts[done[i].id] ?? 0,
                                        isFirst: i == 0, 
                                        isLast: i == done.length - 1
                                      ),
                                    ),
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
  final int attachmentCount;
  final VoidCallback? onInsertRequested;
  const _TaskRow({required this.task, required this.controller, required this.index, this.attachmentCount = 0, this.isFirst = false, this.isLast = false, this.onInsertRequested});
  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _ticking = false;
  bool _unticking = false;
  AnimationController? _strikeCtrl;
  Animation<double>? _strikeAnim;

  bool get _showAsCompleted => (widget.task.isCompleted && !_unticking) || _ticking;

  @override
  void initState() {
    super.initState();
    final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _strikeCtrl = ctrl;
    _strikeAnim = CurvedAnimation(parent: ctrl, curve: Curves.easeInOut);
    if (widget.task.isCompleted) ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_TaskRow old) {
    super.didUpdateWidget(old);
    if (widget.task.isCompleted && !old.task.isCompleted) {
      _strikeCtrl?.forward();
    } else if (!widget.task.isCompleted && old.task.isCompleted) {
      _strikeCtrl?.reverse();
      if (mounted) setState(() { _ticking = false; _unticking = false; });
    }
  }

  @override
  void dispose() {
    _strikeCtrl?.dispose();
    super.dispose();
  }

  void _handleCircleTap() async {
    if (_ticking || _unticking) return;
    if (widget.task.isCompleted) {
      setState(() => _unticking = true);
      _strikeCtrl?.reverse();
      await Future.delayed(const Duration(milliseconds: 380));
      if (mounted) widget.controller.reopenTask(widget.task.id);
      return;
    }
    setState(() => _ticking = true);
    _strikeCtrl?.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) widget.controller.completeTask(widget.task.id);
  }

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
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.22,
          children: [
            if (widget.task.isCompleted)
              CustomSlidableAction(
                onPressed: (_) => widget.controller.reopenTask(widget.task.id),
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                child: const _SwipeActionTile(
                  icon: Icons.replay_rounded,
                  color: AppColors.action,
                ),
              )
            else
              CustomSlidableAction(
                onPressed: (_) => widget.controller.completeTask(widget.task.id),
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                child: const _SwipeActionTile(
                  icon: Icons.check_rounded,
                  color: AppColors.attention,
                ),
              ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.22,
          children: [
            CustomSlidableAction(
              onPressed: (_) => widget.controller.deleteTask(widget.task.id),
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              child: const _SwipeActionTile(
                icon: Icons.delete_outline_rounded,
                color: AppColors.alert,
              ),
            ),
          ],
        ),
        child: Container(
          height: 76,
          padding: const EdgeInsets.only(left: 12, right: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 3))],
          ),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleCircleTap,
                child: SizedBox(
                  width: 44, height: 76,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _showAsCompleted
                            ? AppColors.action
                            : Colors.transparent,
                        border: Border.all(
                          color: _showAsCompleted
                              ? AppColors.action
                              : AppColors.textSecondaryOpacity(0.28),
                          width: 1.6,
                        ),
                      ),
                      child: _showAsCompleted
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _showAsCompleted
                                ? AppColors.textSecondaryOpacity(0.38)
                                : AppColors.textPrimary,
                          ),
                          child: Text(widget.task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _strikeAnim ?? const AlwaysStoppedAnimation(0),
                            builder: (_, __) => CustomPaint(
                              painter: _StrikePainter(
                                progress: _strikeAnim?.value ?? 0,
                                color: AppColors.textSecondaryOpacity(0.55),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.task.dueAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          relativeDueLabel(widget.task.dueAt),
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500, 
                            color: widget.task.isOverdue ? AppColors.alert : AppColors.textSecondaryOpacity(0.7),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.task.category != null && widget.task.category!.isNotEmpty)
                Flexible(
                  flex: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(widget.task.category!).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.task.category!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _getCategoryColor(widget.task.category!)),
                    ),
                  ),
                ),
              if (widget.attachmentCount > 0) ...[
                const SizedBox(width: 8),
                Icon(Icons.attach_file, size: 14, color: AppColors.textSecondary),
                if (widget.attachmentCount > 1) ...[
                  const SizedBox(width: 4),
                  Text('${widget.attachmentCount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary)),
                ],
              ],
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
  final Color color;
  const _SwipeActionTile({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: 26),
      ),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.action : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: AppColors.divider, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.surface : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StrikePainter extends CustomPainter {
  final double progress;
  final Color color;
  const _StrikePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final y = size.height * 0.52;
    canvas.drawLine(Offset(0, y), Offset(size.width * progress, y), paint);
  }

  @override
  bool shouldRepaint(_StrikePainter old) => old.progress != progress;
}
