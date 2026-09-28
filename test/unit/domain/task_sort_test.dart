import 'package:flutter_test/flutter_test.dart';
import 'package:todow/domain/models/query.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/models/enums.dart';

void main() {
  final now = DateTime.now();
  final t1 = Task(id: '1', title: 'Zebra', description: '', status: TaskStatus.active, priority: TaskPriority.low, createdAt: now.add(const Duration(seconds: 1)), updatedAt: now, dueAt: now.add(const Duration(days: 1)), sortOrder: 2);
  final t2 = Task(id: '2', title: 'Apple', description: '', status: TaskStatus.active, priority: TaskPriority.critical, createdAt: now, updatedAt: now, dueAt: null, sortOrder: 0);
  final t3 = Task(id: '3', title: 'Banana', description: '', status: TaskStatus.active, priority: TaskPriority.high, createdAt: now.add(const Duration(seconds: 2)), updatedAt: now, dueAt: now.subtract(const Duration(days: 1)), sortOrder: 1);

  final tasks = [t1, t2, t3];

  test('manual uses sortOrder ascending', () {
    final sorted = sortTasks(tasks, TaskSort.manual);
    expect(sorted.map((t) => t.id).toList(), ['2', '3', '1']);
  });

  test('dueDateAsc puts null dueAt last', () {
    final sorted = sortTasks(tasks, TaskSort.dueDateAsc);
    expect(sorted.map((t) => t.id).toList(), ['3', '1', '2']);
  });

  test('priorityDesc', () {
    final sorted = sortTasks(tasks, TaskSort.priorityDesc);
    expect(sorted.map((t) => t.id).toList(), ['2', '3', '1']);
  });

  test('createdDesc', () {
    final sorted = sortTasks(tasks, TaskSort.createdDesc);
    expect(sorted.map((t) => t.id).toList(), ['3', '1', '2']);
  });

  test('titleAsc', () {
    final sorted = sortTasks(tasks, TaskSort.titleAsc);
    expect(sorted.map((t) => t.id).toList(), ['2', '3', '1']);
  });

  test('stable: same priority preserves manual order', () {
    final t4 = Task(id: '4', title: 'Same Pri 1', description: '', status: TaskStatus.active, priority: TaskPriority.none, createdAt: now, updatedAt: now, sortOrder: 3);
    final t5 = Task(id: '5', title: 'Same Pri 2', description: '', status: TaskStatus.active, priority: TaskPriority.none, createdAt: now, updatedAt: now, sortOrder: 4);
    final sorted = sortTasks([t5, t4], TaskSort.priorityDesc);
    expect(sorted.map((t) => t.id).toList(), ['4', '5']); // 4 comes before 5 in manual sort
  });
}
