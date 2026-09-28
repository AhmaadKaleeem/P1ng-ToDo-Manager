import 'package:flutter_test/flutter_test.dart';
import 'package:todow/domain/models/query.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/models/enums.dart';

void main() {
  final t1 = Task(id: '1', title: 'Buy milk', description: 'At the store', status: TaskStatus.active, priority: TaskPriority.none, createdAt: DateTime.now(), updatedAt: DateTime.now(), sortOrder: 0);
  final t2 = Task(id: '2', title: 'Report draft', description: 'Finish the Q3 report', status: TaskStatus.active, priority: TaskPriority.high, createdAt: DateTime.now(), updatedAt: DateTime.now(), sortOrder: 1);
  final tasks = [t1, t2];

  test('empty query returns all tasks', () {
    expect(searchTasks(tasks, ''), equals(tasks));
  });

  test('case-insensitive match', () {
    expect(searchTasks(tasks, 'REPORT').length, 1);
    expect(searchTasks(tasks, 'REPORT').first.id, '2');
  });

  test('searches title AND description', () {
    expect(searchTasks(tasks, 'store').length, 1);
    expect(searchTasks(tasks, 'store').first.id, '1');
  });

  test('no match returns empty list', () {
    expect(searchTasks(tasks, 'xyz123'), isEmpty);
  });

  test('whitespace-only query treated as empty', () {
    expect(searchTasks(tasks, '   '), equals(tasks));
  });

  test('special chars do not throw', () {
    expect(() => searchTasks(tasks, '?[*'), returnsNormally);
    expect(searchTasks(tasks, '?[*'), isEmpty);
  });
}
