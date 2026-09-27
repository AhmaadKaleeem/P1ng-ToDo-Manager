import 'package:flutter_test/flutter_test.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/task.dart';

void main() {
  test('creates a local task without starter counter state', () {
    final task = Task(
      id: 'task-1',
      title: 'Read operating systems chapter',
      description: '',
      status: TaskStatus.inbox,
      priority: TaskPriority.medium,
      createdAt: DateTime(2026, 9, 18),
      updatedAt: DateTime(2026, 9, 18),
    );

    expect(task.title, 'Read operating systems chapter');
    expect(task.sourceType, TaskSourceType.local);
  });
}
