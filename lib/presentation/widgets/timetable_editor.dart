import 'dart:async';

import 'package:flutter/material.dart';
import 'package:p1ng_todo_manager/domain/models/enums.dart';
import 'package:p1ng_todo_manager/presentation/controllers/timetable_controller.dart';
import 'package:provider/provider.dart';


Future<void> showTimetableEditor(BuildContext context) async {
  final course = TextEditingController();
  final instructor = TextEditingController();
  final room = TextEditingController();
  var weekday = Weekday.values[DateTime.now().weekday - 1];
  var start = const TimeOfDay(hour: 9, minute: 0);
  var end = const TimeOfDay(hour: 10, minute: 0);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add class'),
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
                  await context.read<TimetableController>().add(
                      courseName: course.text,
                      instructor: instructor.text,
                      weekday: weekday,
                      startTime: DateTime(now.year, now.month, now.day,
                          start.hour, start.minute),
                      endTime: DateTime(
                          now.year, now.month, now.day, end.hour, end.minute),
                      room: room.text);
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
              child: const Text('Add')),
        ],
      ),
    ),
  );
  course.dispose();
  instructor.dispose();
  room.dispose();
}
