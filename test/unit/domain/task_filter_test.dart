import 'package:flutter_test/flutter_test.dart';
import 'package:todow/domain/models/query.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/models/enums.dart';

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final yesterday = today.subtract(const Duration(days: 1));

  final tOpen = Task(id: '1', title: 'Open Task', description: '', status: TaskStatus.active, priority: TaskPriority.none, createdAt: now, updatedAt: now, dueAt: null, sortOrder: 0);
  final tCompleted = Task(id: '2', title: 'Completed Task', description: '', status: TaskStatus.completed, priority: TaskPriority.none, createdAt: now, updatedAt: now, dueAt: null, sortOrder: 1);
  final tHigh = Task(id: '3', title: 'High Priority', description: '', status: TaskStatus.active, priority: TaskPriority.high, createdAt: now, updatedAt: now, dueAt: null, sortOrder: 2);
  final tCritical = Task(id: '4', title: 'Critical Priority', description: '', status: TaskStatus.active, priority: TaskPriority.critical, createdAt: now, updatedAt: now, dueAt: null, sortOrder: 3);
  final tOverdue = Task(id: '5', title: 'Overdue', description: '', status: TaskStatus.active, priority: TaskPriority.none, createdAt: now, updatedAt: now, dueAt: yesterday, sortOrder: 4);
  final tToday = Task(id: '6', title: 'Today', description: '', status: TaskStatus.active, priority: TaskPriority.none, createdAt: now, updatedAt: now, dueAt: today, sortOrder: 5);
  final tThisWeek = Task(id: '7', title: 'This Week', description: '', status: TaskStatus.active, priority: TaskPriority.none, createdAt: now, updatedAt: now, dueAt: tomorrow, sortOrder: 6);

  final tasks = [tOpen, tCompleted, tHigh, tCritical, tOverdue, tToday, tThisWeek];

  test('empty filter returns all tasks', () {
    expect(filterTasks(tasks, const TaskFilter(status: TaskStatusFilter.all)), equals(tasks));
  });

  test('status=open excludes completed', () {
    final filtered = filterTasks(tasks, TaskFilter(status: TaskStatusFilter.open));
    expect(filtered.contains(tCompleted), isFalse);
    expect(filtered.contains(tOpen), isTrue);
  });

  test('status=completed returns only completed', () {
    final filtered = filterTasks(tasks, TaskFilter(status: TaskStatusFilter.completed));
    expect(filtered.length, 1);
    expect(filtered.first.id, '2');
  });

  test('priority multi-select returns union', () {
    final filtered = filterTasks(tasks, TaskFilter(priorities: {TaskPriority.high, TaskPriority.critical}));
    expect(filtered.length, 2);
    expect(filtered.map((t) => t.id).toSet(), {'3', '4'});
  });

  test('due=overdue', () {
    final filtered = filterTasks(tasks, TaskFilter(due: {DueFilter.overdue}));
    expect(filtered.length, 1);
    expect(filtered.first.id, '5');
  });

  test('due=today', () {
    final filtered = filterTasks(tasks, TaskFilter(due: {DueFilter.today}));
    expect(filtered.length, 1);
    expect(filtered.first.id, '6');
  });

  test('due=thisWeek', () {
    final filtered = filterTasks(tasks, TaskFilter(due: {DueFilter.thisWeek}));
    expect(filtered.length, 2); // Today is also this week
    expect(filtered.map((t) => t.id).toSet(), {'6', '7'});
  });

  test('due=noDate', () {
    final filtered = filterTasks(tasks, TaskFilter(status: TaskStatusFilter.all, due: {DueFilter.noDate}));
    expect(filtered.length, 4);
    expect(filtered.map((t) => t.id).toSet(), {'1', '2', '3', '4'});
  });

  test('combined status+priority+due compose correctly', () {
    final filtered = filterTasks(tasks, TaskFilter(
      status: TaskStatusFilter.open,
      priorities: {TaskPriority.high, TaskPriority.critical},
      due: {DueFilter.noDate}
    ));
    expect(filtered.length, 2);
    expect(filtered.map((t) => t.id).toSet(), {'3', '4'});
  });
}
