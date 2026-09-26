import 'dart:async';

import 'package:flutter/material.dart';
import 'package:p1ng_todo_manager/core/theme/app_colors.dart';
import 'package:p1ng_todo_manager/core/utils/date_format.dart';
import 'package:p1ng_todo_manager/domain/models/enums.dart';
import 'package:p1ng_todo_manager/domain/models/reminder.dart';
import 'package:p1ng_todo_manager/domain/models/task.dart';
import 'package:p1ng_todo_manager/domain/reminders/reminder_presets.dart';
import 'package:p1ng_todo_manager/presentation/controllers/task_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';


Future<void> showTaskEditor(BuildContext context, {Task? task}) async {
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => _TaskEditor(task: task));
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({this.task});
  final Task? task;

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  DateTime? _dueAt;
  TaskPriority _priority = TaskPriority.medium;
  ReminderPreset _preset = ReminderPreset.normal;
  bool _constantReminder = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title);
    _description = TextEditingController(text: task?.description);
    _dueAt = task?.dueAt;
    _priority = task?.priority ?? TaskPriority.medium;
    _preset = task?.reminderPlan.preset ?? ReminderPreset.normal;
    _constantReminder = task?.hasConstantReminder ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(widget.task == null ? 'New task' : 'Edit task',
                  style: Theme.of(context).textTheme.headlineMedium)),
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close))
        ]),
        const SizedBox(height: 16),
        TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(
                labelText: 'Title', hintText: 'What needs your attention?')),
        const SizedBox(height: 12),
        TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Notes', hintText: 'Optional context')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: DropdownButtonFormField<TaskPriority>(
                  value: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: TaskPriority.values
                      .map((value) => DropdownMenuItem(
                          value: value, child: Text(value.label)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _priority = value ?? _priority))),
          const SizedBox(width: 12),
          Expanded(
              child: DropdownButtonFormField<ReminderPreset>(
                  value: _preset,
                  decoration: const InputDecoration(labelText: 'Reminders'),
                  items: [
                    ReminderPreset.normal,
                    ReminderPreset.assignment,
                    ReminderPreset.critical
                  ]
                      .map((value) => DropdownMenuItem(
                          value: value, child: Text(value.label)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _preset = value ?? _preset))),
        ]),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: _pickDueDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(_dueAt == null
                ? 'Set due date and time'
                : AppDateFormat.dateTime(_dueAt!))),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: widget.task == null ? null : _pickAttachment,
          icon: const Icon(Icons.attach_file),
          label: Text(widget.task == null
              ? 'Save task before attaching files'
              : 'Attach image or file'),
        ),
        if (widget.task?.attachments.isNotEmpty == true)
          ...widget.task!.attachments.map(
            (attachment) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(attachment.fileName),
            ),
          ),
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Constant reminder'),
            subtitle: const Text(
                'Keep reminding me until I complete or reschedule it.'),
            value: _constantReminder,
            onChanged: (value) => setState(() => _constantReminder = value)),
        const SizedBox(height: 12),
        SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : Text(
                        widget.task == null ? 'Create task' : 'Save changes'))),
      ])),
    );
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 3650)),
        initialDate: _dueAt ?? DateTime.now());
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context,
        initialTime: _dueAt == null
            ? const TimeOfDay(hour: 23, minute: 59)
            : TimeOfDay.fromDateTime(_dueAt!));
    if (time == null) return;
    setState(() => _dueAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    final file = result?.files.single;
    if (file?.path == null || widget.task == null || !mounted) return;
    try {
      await context.read<TaskController>().attachFile(
            widget.task!.id,
            file!.path!,
            file.name,
          );
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final controller = context.read<TaskController>();
    try {
      final plan = ReminderPlan(
          preset: _preset,
          offsets: ReminderPresets.forPreset(_preset),
          constantReminder: _constantReminder);
      if (widget.task == null) {
        await controller.createTask(
            title: _title.text,
            description: _description.text,
            priority: _priority,
            dueAt: _dueAt,
            reminderPlan: plan);
      } else {
        await controller.updateTask(widget.task!.copyWith(
            title: _title.text,
            description: _description.text,
            priority: _priority,
            dueAt: _dueAt,
            reminderPlan: plan));
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
