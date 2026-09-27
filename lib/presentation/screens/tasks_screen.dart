import 'package:flutter/material.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'package:todow/core/utils/date_format.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/repositories/task_repository.dart';
import 'package:todow/presentation/controllers/task_controller.dart';
import 'package:provider/provider.dart';

import 'package:todow/presentation/app.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<TaskSort>(
            icon: const Icon(Icons.sort),
            onSelected: controller.setSort,
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: TaskSort.dueDateAsc, child: Text('Due soonest')),
              PopupMenuItem(
                  value: TaskSort.priorityDesc, child: Text('Priority')),
              PopupMenuItem(
                  value: TaskSort.createdDesc, child: Text('Recently added')),
              PopupMenuItem(value: TaskSort.titleAsc, child: Text('Title')),
            ],
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: TextField(
            controller: _search,
            onChanged: controller.setQuery,
            decoration: const InputDecoration(
                hintText: 'Search tasks', prefixIcon: Icon(Icons.search)),
          ),
        ),
        Expanded(
          child: controller.loading
              ? const Center(child: CircularProgressIndicator())
              : controller.tasks.isEmpty
                  ? const AppEmptyState(
                      title: 'No tasks yet',
                      message: 'Capture the next thing you need to remember.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: controller.tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) =>
                          TaskRow(task: controller.tasks[index]),
                    ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaskEditorScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
    );
  }
}

class TaskRow extends StatelessWidget {
  const TaskRow({required this.task, super.key});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TaskController>();
    final dueColor =
        task.isOverdue ? AppColors.alert : AppColors.textSecondary;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        leading: IconButton(
          icon: Icon(
              task.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: task.isCompleted
                  ? AppColors.action
                  : AppColors.textSecondary),
          tooltip: task.isCompleted ? 'Reopen task' : 'Complete task',
          onPressed: () => task.isCompleted
              ? controller.reopenTask(task.id)
              : controller.completeTask(task.id),
        ),
        title: Text(task.title,
            style: TextStyle(
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null)),
        subtitle: Row(children: [
          if (task.dueAt != null)
            Text(AppDateFormat.dueLabel(task.dueAt),
                style: TextStyle(color: dueColor, fontSize: 12)),
          if (task.hasConstantReminder) ...[
            const SizedBox(width: 8),
            const Icon(Icons.notifications_active_outlined,
                size: 14, color: AppColors.alert)
          ],
          if (task.hasAttachments) ...[
            const SizedBox(width: 8),
            const Icon(Icons.attach_file, size: 14)
          ],
        ]),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskEditorScreen(task: task)));
            if (value == 'duplicate') await controller.duplicateTask(task.id);
            if (value == 'archive') await controller.archiveTask(task.id);
            if (value == 'delete') await controller.deleteTask(task.id);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
            PopupMenuItem(value: 'archive', child: Text('Archive')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}


