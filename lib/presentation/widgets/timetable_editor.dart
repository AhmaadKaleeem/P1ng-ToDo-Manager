import 'dart:async';

import 'package:flutter/material.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/timetable_entry.dart';
import 'package:todow/presentation/controllers/timetable_controller.dart';
import 'package:provider/provider.dart';

Future<void> showTimetableEditor(
  BuildContext context, {
  TimetableEntry? entry,
  Weekday? initialWeekday,
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
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(entry == null ? 'Add class' : 'Edit class'),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: course,
              decoration: const InputDecoration(labelText: 'Course name')),
          TextField(
              controller: instructor,
              decoration: const InputDecoration(labelText: 'Instructor')),
          TextField(
              controller: room,
              decoration: const InputDecoration(labelText: 'Room')),
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
                      startTime: startTime,
                      endTime: endTime,
                      room: room.text.trim().isEmpty ? null : room.text.trim(),
                      colorValue: entry.colorValue,
                      category: entry.category,
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
