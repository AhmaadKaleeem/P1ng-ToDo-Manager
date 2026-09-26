import 'dart:async';

import 'package:flutter/material.dart';
import 'package:p1ng_todo_manager/bootstrap.dart';
import 'package:p1ng_todo_manager/core/theme/app_colors.dart';
import 'package:p1ng_todo_manager/core/utils/date_format.dart';
import 'package:p1ng_todo_manager/domain/models/enums.dart';
import 'package:p1ng_todo_manager/domain/models/focus_session.dart';
import 'package:p1ng_todo_manager/domain/models/reminder.dart';
import 'package:p1ng_todo_manager/domain/models/task.dart';
import 'package:p1ng_todo_manager/domain/models/timetable_entry.dart';
import 'package:p1ng_todo_manager/domain/reminders/reminder_presets.dart';
import 'package:p1ng_todo_manager/domain/repositories/task_repository.dart';
import 'package:p1ng_todo_manager/presentation/controllers/focus_controller.dart';
import 'package:p1ng_todo_manager/presentation/controllers/task_controller.dart';
import 'package:p1ng_todo_manager/presentation/controllers/timetable_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import 'package:p1ng_todo_manager/presentation/app.dart';
import 'package:p1ng_todo_manager/presentation/widgets/empty_state.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TimetableController>();
    final today = WeekdayExt.fromDartWeekday(DateTime.now().weekday);
    final entries = controller.forDay(today);
    return Scaffold(
      appBar: AppBar(title: const Text('Timetable'), actions: [
        IconButton(
            onPressed: () => showTimetableEditor(context),
            icon: const Icon(Icons.add),
            tooltip: 'Add class')
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(today.fullLabel.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: AppColors.action)),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          const AppEmptyState(
              title: 'No classes today',
              message: 'Keep your weekly rhythm here when you need it.')
        else
          ...entries.map((entry) => _TimetableRow(entry: entry)),
      ]),
    );
  }
}

class _TimetableRow extends StatelessWidget {
  const _TimetableRow({required this.entry});
  final TimetableEntry entry;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TimetableController>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          title: Text(entry.courseName),
          subtitle: Text(
              '${AppDateFormat.time(entry.startTime)} - ${AppDateFormat.time(entry.endTime)}  ${entry.room ?? ''}'),
          trailing: IconButton(
              onPressed: () => controller.delete(entry.id),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete class'),
        ),
      ),
    );
  }
}

