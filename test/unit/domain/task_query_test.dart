import 'package:flutter_test/flutter_test.dart';
import 'package:todow/domain/models/query.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/models/enums.dart';

void main() {
  final now = DateTime.now();
  final t1 = Task(id: '1', title: 'Buy milk', description: '', status: TaskStatus.active, priority: TaskPriority.none, createdAt: now, updatedAt: now, sortOrder: 2);
  final t2 = Task(id: '2', title: 'Report draft', description: '', status: TaskStatus.active, priority: TaskPriority.high, createdAt: now, updatedAt: now, sortOrder: 1);
  final t3 = Task(id: '3', title: 'Completed milk', description: '', status: TaskStatus.completed, priority: TaskPriority.none, createdAt: now, updatedAt: now, sortOrder: 0);

  final tasks = [t1, t2, t3];

  test('search + filter + sort returns intersection in sorted order', () {
    final query = SearchQuery(
      text: 'milk',
      filter: TaskFilter(status: TaskStatusFilter.all),
      sort: TaskSort.manual
    );
    final result = applyQuery(tasks, query);
    expect(result.map((t) => t.id).toList(), ['3', '1']);
  });

  test('search empty + filter active', () {
    final query = SearchQuery(
      text: '',
      filter: TaskFilter(status: TaskStatusFilter.completed),
      sort: TaskSort.manual
    );
    final result = applyQuery(tasks, query);
    expect(result.map((t) => t.id).toList(), ['3']);
  });

  test('filter empty + search active', () {
    final query = SearchQuery(
      text: 'draft',
      filter: TaskFilter.empty(),
      sort: TaskSort.manual
    );
    final result = applyQuery(tasks, query);
    expect(result.map((t) => t.id).toList(), ['2']);
  });

  test('both empty -> all tasks in sort order', () {
    final query = SearchQuery(
      text: '',
      filter: const TaskFilter(status: TaskStatusFilter.all),
      sort: TaskSort.titleAsc
    );
    final result = applyQuery(tasks, query);
    expect(result.map((t) => t.title).toList(), ['Buy milk', 'Completed milk', 'Report draft']);
  });
}
