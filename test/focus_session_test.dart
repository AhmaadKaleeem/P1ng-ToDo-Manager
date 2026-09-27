import 'package:flutter_test/flutter_test.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/focus_session.dart';

void main() {
  test('keeps elapsed focus time when a paused session ends', () {
    final startedAt = DateTime(2026, 9, 18, 10);
    final session = FocusSession(
      id: 'focus-1',
      taskId: 'task-1',
      taskTitle: 'Study',
      preset: FocusPreset.study,
      plannedDuration: const Duration(minutes: 50),
      startedAt: startedAt,
      status: FocusSessionStatus.ended,
      endedAt: startedAt.add(const Duration(minutes: 20)),
      elapsedBeforePause: const Duration(minutes: 12),
    );

    expect(session.elapsedAt(startedAt), const Duration(minutes: 32));
  });
}
