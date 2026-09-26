
import 'package:flutter/material.dart';
import 'package:p1ng_todo_manager/core/theme/app_colors.dart';
import 'package:p1ng_todo_manager/core/utils/date_format.dart';
import 'package:p1ng_todo_manager/domain/models/task.dart';
import 'package:p1ng_todo_manager/presentation/controllers/task_controller.dart';
import 'package:provider/provider.dart';

import 'package:p1ng_todo_manager/presentation/app.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({required this.onFocus, super.key});

  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskController>();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TODAY',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppColors.action)),
                const SizedBox(height: 6),
                Text(AppDateFormat.date(DateTime.now()),
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 20),
                _FocusBanner(onTap: onFocus),
              ],
            ),
          ),
        ),
        _TaskSection(
            title: 'OVERDUE',
            color: AppColors.alert,
            tasks: tasks.overdueTasks),
        _TaskSection(title: 'TODAY', tasks: tasks.todayTasks),
        _TaskSection(
            title: 'UPCOMING', tasks: tasks.upcomingTasks.take(5).toList()),
        if (!tasks.loading &&
            tasks.overdueTasks.isEmpty &&
            tasks.todayTasks.isEmpty &&
            tasks.upcomingTasks.isEmpty)
          const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                  title: 'Nothing urgent',
                  message:
                      'Add a task with a due date and keep the important work visible.')),
      ],
    );
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({required this.title, required this.tasks, this.color});

  final String title;
  final List<Task> tasks;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      sliver: SliverList.list(children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: color ?? AppColors.textSecondary())),
        const SizedBox(height: 8),
        ...tasks.map((task) => TaskRow(task: task)),
      ]),
    );
  }
}

class _FocusBanner extends StatelessWidget {
  const _FocusBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.action.withValues(alpha: .12),
          border: Border.all(color: AppColors.action.withValues(alpha: .35)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(children: [
          Icon(Icons.play_circle_outline, color: AppColors.action, size: 30),
          SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('FOCUS MODE'),
                SizedBox(height: 3),
                Text('Protect the next block of your attention.')
              ])),
          Icon(Icons.arrow_forward, color: AppColors.action),
        ]),
      ),
    );
  }
}
