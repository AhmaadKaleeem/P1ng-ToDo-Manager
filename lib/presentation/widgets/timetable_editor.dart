import 'dart:async';

import 'package:flutter/material.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/timetable_entry.dart';
import 'package:todow/presentation/controllers/timetable_controller.dart';
import 'package:provider/provider.dart';
import 'package:todow/presentation/controllers/task_controller.dart';

Future<void> showTimetableEditor(
  BuildContext context, {
  TimetableEntry? entry,
  Weekday? initialWeekday,
  DateTime? initialDate,
  TimetableKind scheduleKind = TimetableKind.university,
}) async {
  final course = TextEditingController(text: entry?.courseName);
  final instructor = TextEditingController(text: entry?.instructor);
  final room = TextEditingController(text: entry?.room);
  var weekday = entry?.weekday ??
      initialWeekday ??
      Weekday.values[DateTime.now().weekday - 1];
  var start = entry == null
      ? const TimeOfDay(hour: 9, minute: 0)
      : TimeOfDay.fromDateTime(entry.startTime);
  var end = entry == null
      ? const TimeOfDay(hour: 10, minute: 0)
      : TimeOfDay.fromDateTime(entry.endTime);
  var scheduledDate = entry?.scheduledDate ?? initialDate ?? DateTime.now();
  var repeatWeekly =
      entry?.repeatWeekly ?? scheduleKind == TimetableKind.university;
  var taskId = entry?.taskId;
  var category = entry?.category ?? 'Activity';
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(entry == null
            ? scheduleKind == TimetableKind.personal
                ? 'Add to personal timetable'
                : 'Add class'
            : scheduleKind == TimetableKind.personal
                ? 'Edit activity'
                : 'Edit class'),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: course,
              decoration: InputDecoration(
                  labelText: scheduleKind == TimetableKind.personal
                      ? 'Activity name'
                      : 'Course name')),
          TextField(
              controller: instructor,
              decoration: InputDecoration(
                  labelText: scheduleKind == TimetableKind.personal
                      ? 'Notes (optional)'
                      : 'Instructor')),
          TextField(
              controller: room,
              decoration: InputDecoration(
                  labelText: scheduleKind == TimetableKind.personal
                      ? 'Place (optional)'
                      : 'Room')),
          if (scheduleKind == TimetableKind.personal) ...[
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                'Activity',
                'Study',
                'Appointment',
                'Work',
                'Task',
                'Roadmap'
              ]
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => category = value ?? 'Activity'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: taskId,
              decoration: const InputDecoration(
                  labelText: 'Link an existing task (optional)'),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('No linked task')),
                ...context.read<TaskController>().tasks.map((task) =>
                    DropdownMenuItem<String?>(
                        value: task.id,
                        child:
                            Text(task.title, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (value) => setState(() => taskId = value),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Repeat every week'),
              value: repeatWeekly,
              onChanged: (value) =>
                  setState(() => repeatWeekly = value ?? false),
            ),
            if (!repeatWeekly)
              TextButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: scheduledDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() {
                      scheduledDate = date;
                      weekday = WeekdayExt.fromDartWeekday(date.weekday);
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                    'Date: ${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}'),
              ),
          ],
          DropdownButtonFormField<Weekday>(
              value: weekday,
              items: Weekday.values
                  .map((day) =>
                      DropdownMenuItem(value: day, child: Text(day.fullLabel)))
                  .toList(),
              onChanged: (value) => setState(() => weekday = value ?? weekday)),
          Row(children: [
            Expanded(
                child: TextButton(
                    onPressed: () async {
                      final value = await showTimePicker(
                          context: context, initialTime: start);
                      if (value != null) setState(() => start = value);
                    },
                    child: Text('Start ${start.format(context)}'))),
            Expanded(
                child: TextButton(
                    onPressed: () async {
                      final value = await showTimePicker(
                          context: context, initialTime: end);
                      if (value != null) setState(() => end = value);
                    },
                    child: Text('End ${end.format(context)}'))),
          ]),
        ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () async {
                final now = DateTime.now();
                try {
                  final startTime = DateTime(
                      now.year, now.month, now.day, start.hour, start.minute);
                  final endTime = DateTime(
                      now.year, now.month, now.day, end.hour, end.minute);
                  final controller = context.read<TimetableController>();
                  if (entry == null) {
                    await controller.add(
                      courseName: course.text,
                      instructor: instructor.text,
                      weekday: weekday,
                      scheduleKind: scheduleKind,
                      scheduledDate: scheduleKind == TimetableKind.personal &&
                              !repeatWeekly
                          ? scheduledDate
                          : null,
                      repeatWeekly: repeatWeekly,
                      taskId: taskId,
                      category: scheduleKind == TimetableKind.personal
                          ? category
                          : null,
                      startTime: startTime,
                      endTime: endTime,
                      room: room.text,
                    );
                  } else {
                    await controller.update(TimetableEntry(
                      id: entry.id,
                      courseName: course.text.trim(),
                      instructor: instructor.text.trim(),
                      weekday: weekday,
                      scheduleKind: entry.scheduleKind,
                      startTime: startTime,
                      endTime: endTime,
                      room: room.text.trim().isEmpty ? null : room.text.trim(),
                      colorValue: entry.colorValue,
                      scheduledDate: scheduleKind == TimetableKind.personal &&
                              !repeatWeekly
                          ? scheduledDate
                          : null,
                      repeatWeekly: repeatWeekly,
                      taskId: taskId,
                      category: scheduleKind == TimetableKind.personal
                          ? category
                          : null,
                    ));
                  }
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.toString())));
                  }
                }
              },
              child: Text(entry == null ? 'Add class' : 'Save changes')),
        ],
      ),
    ),
  );
  course.dispose();
  instructor.dispose();
  room.dispose();
}
