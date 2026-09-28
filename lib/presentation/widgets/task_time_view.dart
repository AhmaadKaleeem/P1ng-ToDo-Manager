import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'package:todow/domain/models/roadmap.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/presentation/controllers/roadmap_controller.dart';
import 'package:todow/presentation/screens/task_editor_screen.dart';

enum TimeFilter { today, thisWeek, upcoming, all }

class TaskTimeView extends StatefulWidget {
  const TaskTimeView({required this.roadmapId, required this.topics, super.key});
  final String roadmapId;
  final List<Topic> topics;

  @override
  State<TaskTimeView> createState() => _TaskTimeViewState();
}

class _TaskTimeViewState extends State<TaskTimeView> {
  TimeFilter _filter = TimeFilter.all;
  List<Task> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    final ctrl = context.read<RoadmapController>();

    DateTime? from;
    DateTime? to;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_filter) {
      case TimeFilter.today:
        from = today;
        to = today.add(const Duration(days: 1, microseconds: -1));
      case TimeFilter.thisWeek:
        from = today;
        to = today.add(const Duration(days: 7, microseconds: -1));
      case TimeFilter.upcoming:
        from = today.add(const Duration(days: 7));
      case TimeFilter.all:
        break;
    }

    final tasks = await ctrl.getTasksByRoadmap(widget.roadmapId, from: from, to: to);
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  void _setFilter(TimeFilter f) {
    if (_filter == f) return;
    setState(() => _filter = f);
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _FilterPill(label: 'TODAY', selected: _filter == TimeFilter.today, onTap: () => _setFilter(TimeFilter.today)),
              _FilterPill(label: 'THIS WEEK', selected: _filter == TimeFilter.thisWeek, onTap: () => _setFilter(TimeFilter.thisWeek)),
              _FilterPill(label: 'UPCOMING', selected: _filter == TimeFilter.upcoming, onTap: () => _setFilter(TimeFilter.upcoming)),
              _FilterPill(label: 'ALL', selected: _filter == TimeFilter.all, onTap: () => _setFilter(TimeFilter.all)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: AppColors.action)))
        else if (_tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40.0),
            child: Text('No scheduled tasks for this period.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _TopicTaskGroups(
              key: ValueKey(_filter),
              tasks: _tasks,
              topics: widget.topics,
              onTaskTap: (task) async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskEditorScreen(task: task)));
                _loadTasks();
              },
            ),
          ),
      ],
    );
  }
}

class _TopicTaskGroups extends StatelessWidget {
  const _TopicTaskGroups({required super.key, required this.tasks, required this.topics, required this.onTaskTap});

  final List<Task> tasks;
  final List<Topic> topics;
  final ValueChanged<Task> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final grouped = {for (final topic in topics) topic.id: <Task>[]};
    final topicTitles = {for (final topic in topics) topic.id: topic.title};
    for (final task in tasks) {
      grouped.putIfAbsent(task.topicId ?? '', () => []).add(task);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in grouped.entries.where((entry) => entry.value.isNotEmpty)) ...[
            Text(
              topicTitles[entry.key] ?? 'UNASSIGNED',
              style: const TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            for (final task in entry.value) ...[
              _TimeTaskRow(task: task, onTap: () => onTaskTap(task)),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _TimeTaskRow extends StatelessWidget {
  const _TimeTaskRow({required this.task, required this.onTap});

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  task.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: task.isCompleted ? AppColors.action : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: task.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      );
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.textPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? AppColors.textPrimary : AppColors.divider),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: selected ? AppColors.surface : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
