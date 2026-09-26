import 'dart:async';

import 'package:flutter/material.dart';
import 'package:p1ng_todo_manager/core/theme/app_colors.dart';
import 'package:p1ng_todo_manager/core/utils/date_format.dart';
import 'package:p1ng_todo_manager/domain/models/enums.dart';
import 'package:p1ng_todo_manager/domain/models/focus_session.dart';
import 'package:p1ng_todo_manager/presentation/controllers/focus_controller.dart';
import 'package:p1ng_todo_manager/presentation/controllers/task_controller.dart';
import 'package:provider/provider.dart';


class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  Timer? _ticker;
  FocusPreset _preset = FocusPreset.study;
  String? _taskId;

  @override
  void initState() {
    super.initState();
    _ticker =
        Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusController>();
    final tasks = context.watch<TaskController>().activeTasks;
    final session = focus.session;
    if (session != null) {
      return _ActiveFocus(
          session: session,
          remaining: focus.remaining(DateTime.now()),
          focus: focus);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Focus')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('A deliberate block of attention.',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: _taskId,
          decoration: const InputDecoration(labelText: 'Task (optional)'),
          items: tasks
              .map((task) => DropdownMenuItem(
                  value: task.id,
                  child: Text(task.title, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (value) => setState(() => _taskId = value),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<FocusPreset>(
          value: _preset,
          decoration: const InputDecoration(labelText: 'Preset'),
          items: FocusPreset.values
              .map((preset) => DropdownMenuItem(
                  value: preset,
                  child: Text(
                      '${preset.label} - ${preset.defaultDuration.inMinutes} min')))
              .toList(),
          onChanged: (value) => setState(() => _preset = value ?? _preset),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () async {
            final task = _taskId == null
                ? null
                : tasks.firstWhere((task) => task.id == _taskId);
            await focus.start(task: task, preset: _preset);
            setState(() {});
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start focus'),
        ),
      ]),
    );
  }
}

class _ActiveFocus extends StatelessWidget {
  const _ActiveFocus(
      {required this.session, required this.remaining, required this.focus});

  final FocusSession session;
  final Duration remaining;
  final FocusController focus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('FOCUSING',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppColors.action)),
            const SizedBox(height: 18),
            Text(session.taskTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 32),
            Text(AppDateFormat.timerDuration(remaining),
                style:
                    const TextStyle(fontSize: 54, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            LinearProgressIndicator(
                value: session.progressAt(DateTime.now()), minHeight: 8),
            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (session.status == FocusSessionStatus.running)
                FilledButton.icon(
                    onPressed: focus.pause,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'))
              else
                FilledButton.icon(
                    onPressed: focus.resume,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume')),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                  onPressed: focus.end,
                  icon: const Icon(Icons.stop),
                  label: const Text('End')),
            ]),
          ]),
        ),
      ),
    );
  }
}
