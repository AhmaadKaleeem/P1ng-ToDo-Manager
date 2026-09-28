import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'package:todow/domain/models/roadmap.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/presentation/controllers/roadmap_controller.dart';
import 'package:todow/presentation/controllers/task_controller.dart';
import 'package:todow/presentation/screens/task_editor_screen.dart';

// Even index → card aligned left side; odd → right side.
// This drives the zigzag composition.
const _kActiveWidthFactor = 0.92;
const _kPendingWidthFactor = 0.80;
const _kCompletedWidthFactor = 0.76;

class TopicCard extends StatefulWidget {
  const TopicCard({
    required this.topic,
    required this.roadmap,
    required this.index,
    required this.onStatusChanged,
    required this.onTasksChanged,
    required this.onGeometryChanged,
    required this.cardKey,
    super.key,
  });

  final Topic topic;
  final Roadmap roadmap;
  final int index;
  final ValueChanged<TopicStatus> onStatusChanged;
  final VoidCallback onTasksChanged;
  final VoidCallback onGeometryChanged;
  final GlobalKey cardKey;

  @override
  State<TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<TopicCard> {
  List<Task> _tasks = const [];
  bool _tasksExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void didUpdateWidget(TopicCard old) {
    super.didUpdateWidget(old);
    if (old.topic.id != widget.topic.id) _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks =
        await context.read<RoadmapController>().getTasksByTopic(widget.topic.id);
    if (!mounted) return;
    setState(() => _tasks = tasks);
    widget.onGeometryChanged();
  }

  int get _completed => _tasks.where((t) => t.isCompleted).length;

  double get _progress =>
      widget.topic.status == TopicStatus.completed
          ? 1.0
          : _tasks.isEmpty
              ? 0.0
              : _completed / _tasks.length;

  @override
  Widget build(BuildContext context) {
    final isLeft = widget.index.isEven;
    final status = widget.topic.status;
    final widthFactor = switch (status) {
      TopicStatus.active => _kActiveWidthFactor,
      TopicStatus.pending => _kPendingWidthFactor,
      TopicStatus.completed => _kCompletedWidthFactor,
    };

    return ClipRect(
      child: AnimatedSize(
        key: widget.cardKey,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: Align(
          alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              child: switch (status) {
                TopicStatus.active => _ActiveNode(
                    key: ValueKey('active-${widget.topic.id}'),
                    topic: widget.topic,
                    tasks: _tasks,
                    progress: _progress,
                    completed: _completed,
                    expanded: _tasksExpanded,
                    onExpand: () {
                      setState(() => _tasksExpanded = !_tasksExpanded);
                      widget.onGeometryChanged();
                    },
                    onTaskEdited: _loadTasks,
                    onTasksChanged: widget.onTasksChanged,
                    onStatusChanged: widget.onStatusChanged,
                  ),
                TopicStatus.completed => _CompletedNode(
                    key: ValueKey('completed-${widget.topic.id}'),
                    topic: widget.topic,
                    tasks: _tasks,
                    progress: _progress,
                    completed: _completed,
                    onTap: () => widget.onStatusChanged(TopicStatus.active),
                  ),
                TopicStatus.pending => _PendingNode(
                    key: ValueKey('pending-${widget.topic.id}'),
                    topic: widget.topic,
                    tasks: _tasks,
                    progress: _progress,
                    completed: _completed,
                    onTap: () => widget.onStatusChanged(TopicStatus.active),
                  ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────── ACTIVE NODE ────────────────────────────────
// Largest, most dominant. Full gradient, description, progress, task list.

class _ActiveNode extends StatelessWidget {
  const _ActiveNode({
    super.key,
    required this.topic,
    required this.tasks,
    required this.progress,
    required this.completed,
    required this.expanded,
    required this.onExpand,
    required this.onTaskEdited,
    required this.onTasksChanged,
    required this.onStatusChanged,
  });

  final Topic topic;
  final List<Task> tasks;
  final double progress;
  final int completed;
  final bool expanded;
  final VoidCallback onExpand;
  final VoidCallback onTaskEdited;
  final VoidCallback onTasksChanged;
  final ValueChanged<TopicStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.action, Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.action.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NodeBadge(
                        label: 'CURRENT · ${_ordinal(topic.orderIndex)}',
                        color: Colors.white.withValues(alpha: 0.25),
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        topic.title,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      ),
                      if (topic.description?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 6),
                        Text(
                          topic.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusButton(
                  tooltip: 'Mark ${topic.title} completed',
                  icon: Icons.check_circle_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.75),
                  onTap: () => onStatusChanged(TopicStatus.completed),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Progress bar — always visible
            _NodeProgressBar(
              progress: progress,
              completed: completed,
              total: tasks.length,
              onDark: true,
            ),
            // Task list (expandable)
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 4),
              Divider(height: 32, color: Colors.white.withValues(alpha: 0.20)),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onExpand,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: Colors.white.withValues(alpha: 0.75),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        expanded ? 'Hide tasks' : 'Show ${tasks.length} tasks',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                sizeCurve: Curves.easeOutCubic,
                crossFadeState: expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Column(
                  children: [
                    for (final task in tasks)
                      _TopicTaskRow(
                        task: task,
                        onEdited: onTaskEdited,
                        onChanged: onTasksChanged,
                        onDark: true,
                      ),
                  ],
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
            const SizedBox(height: 8),
            // Add task
            GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TaskEditorScreen(topicId: topic.id),
                  ),
                );
                onTaskEdited();
                onTasksChanged();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded,
                        size: 17,
                        color: Colors.white.withValues(alpha: 0.90)),
                    const SizedBox(width: 6),
                    Text(
                      'Add task',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.90),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────── COMPLETED NODE ─────────────────────────────
// Smaller, quieter. Warm surface, amber accent, settled visual weight.

class _CompletedNode extends StatelessWidget {
  const _CompletedNode({
    super.key,
    required this.topic,
    required this.tasks,
    required this.progress,
    required this.completed,
    required this.onTap,
  });

  final Topic topic;
  final List<Task> tasks;
  final double progress;
  final int completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 148),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: AppColors.attention.withValues(alpha: 0.22), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _NodeBadge(
                    label: 'COMPLETED · ${_ordinal(topic.orderIndex)}',
                    color: AppColors.attention.withValues(alpha: 0.15),
                    textColor: AppColors.attention,
                    icon: Icons.check_rounded,
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      size: 20),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                topic.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _NodeProgressBar(
                progress: progress,
                completed: completed,
                total: tasks.length,
                onDark: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────── PENDING NODE ───────────────────────────────
// Medium size. Light blue-tinted. Clearly part of the path but lighter weight.

class _PendingNode extends StatelessWidget {
  const _PendingNode({
    super.key,
    required this.topic,
    required this.tasks,
    required this.progress,
    required this.completed,
    required this.onTap,
  });

  final Topic topic;
  final List<Task> tasks;
  final double progress;
  final int completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 170),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: AppColors.action.withValues(alpha: 0.14), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.action.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _NodeBadge(
                    label: 'UP NEXT · ${_ordinal(topic.orderIndex)}',
                    color: AppColors.action.withValues(alpha: 0.10),
                    textColor: AppColors.action,
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      size: 20),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                topic.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (topic.description?.isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                Text(
                  topic.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _NodeProgressBar(
                progress: progress,
                completed: completed,
                total: tasks.length,
                onDark: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── SHARED WIDGETS ───────────────────────────────

class _NodeBadge extends StatelessWidget {
  const _NodeBadge({
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
  });

  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeProgressBar extends StatelessWidget {
  const _NodeProgressBar({
    required this.progress,
    required this.completed,
    required this.total,
    required this.onDark,
  });

  final double progress;
  final int completed;
  final int total;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final barBg =
        onDark ? Colors.white.withValues(alpha: 0.22) : AppColors.divider;
    final barFg = onDark ? Colors.white : AppColors.attention;
    final textFg = onDark
        ? Colors.white.withValues(alpha: 0.80)
        : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: barBg,
                  valueColor: AlwaysStoppedAnimation(barFg),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: barFg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '$completed / $total tasks',
          style: TextStyle(fontSize: 12, color: textFg),
        ),
      ],
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

class _TopicTaskRow extends StatelessWidget {
  const _TopicTaskRow({
    required this.task,
    required this.onEdited,
    required this.onChanged,
    this.onDark = false,
  });

  final Task task;
  final VoidCallback onEdited;
  final VoidCallback onChanged;
  final bool onDark;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            IconButton(
              tooltip: task.isCompleted
                  ? 'Reopen ${task.title}'
                  : 'Complete ${task.title}',
              onPressed: () async {
                final ctrl = context.read<TaskController>();
                if (task.isCompleted) {
                  await ctrl.reopenTask(task.id);
                } else {
                  await ctrl.completeTask(task.id);
                }
                if (!context.mounted) return;
                onEdited();
                onChanged();
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  task.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(task.isCompleted),
                  color: task.isCompleted
                      ? (onDark ? Colors.white : AppColors.action)
                      : (onDark
                          ? Colors.white.withValues(alpha: 0.65)
                          : AppColors.textSecondary),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => TaskEditorScreen(task: task)),
                  );
                  if (!context.mounted) return;
                  onEdited();
                  onChanged();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: task.isCompleted
                          ? (onDark
                              ? Colors.white.withValues(alpha: 0.55)
                              : AppColors.textSecondary)
                          : (onDark ? Colors.white : AppColors.textPrimary),
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: onDark
                  ? Colors.white.withValues(alpha: 0.45)
                  : AppColors.textSecondary,
            ),
          ],
        ),
      );
}

// Helpers
String _ordinal(int zeroIndex) =>
    (zeroIndex + 1).toString().padLeft(2, '0');
