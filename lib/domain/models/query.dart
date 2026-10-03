import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/models/enums.dart';

enum TaskSort { manual, dueDateAsc, dueDateDesc, priorityDesc, createdDesc, titleAsc }

enum TaskStatusFilter { open, completed, all }

enum DueFilter { overdue, today, thisWeek, noDate }

class TaskFilter {
  final TaskStatusFilter status;
  final Set<TaskPriority> priorities;
  final Set<DueFilter> due;

  const TaskFilter({
    this.status = TaskStatusFilter.open,
    this.priorities = const {},
    this.due = const {},
  });

  factory TaskFilter.empty() => const TaskFilter();

  TaskFilter copyWith({
    TaskStatusFilter? status,
    Set<TaskPriority>? priorities,
    Set<DueFilter>? due,
  }) {
    return TaskFilter(
      status: status ?? this.status,
      priorities: priorities ?? this.priorities,
      due: due ?? this.due,
    );
  }
}

class SearchQuery {
  final String text;
  final TaskFilter filter;
  final TaskSort sort;

  const SearchQuery({required this.text, required this.filter, required this.sort});
}

List<Task> searchTasks(List<Task> tasks, String query) {
  final cleanQuery = query.trim().toLowerCase();
  if (cleanQuery.isEmpty) return List.from(tasks);
  
  return tasks.where((t) {
    return t.title.toLowerCase().contains(cleanQuery) ||
           t.description.toLowerCase().contains(cleanQuery);
  }).toList();
}

List<Task> filterTasks(List<Task> tasks, TaskFilter filter) {
  return tasks.where((t) {
    if (filter.status != TaskStatusFilter.all) {
      if (filter.status == TaskStatusFilter.completed && t.status != TaskStatus.completed) return false;
      if (filter.status == TaskStatusFilter.open && t.status == TaskStatus.completed) return false;
    }
    
    if (filter.priorities.isNotEmpty && !filter.priorities.contains(t.priority)) return false;
    
    if (filter.due.isNotEmpty) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      bool matchDue = false;
      
      for (final due in filter.due) {
        if (due == DueFilter.noDate && t.dueAt == null) matchDue = true;
        if (t.dueAt != null) {
          final tDue = DateTime(t.dueAt!.year, t.dueAt!.month, t.dueAt!.day);
          if (due == DueFilter.today && tDue.isAtSameMomentAs(today)) matchDue = true;
          if (due == DueFilter.thisWeek && !tDue.isBefore(today) && !tDue.isAfter(today.add(const Duration(days: 7)))) matchDue = true;
          if (due == DueFilter.overdue && tDue.isBefore(today) && t.status != TaskStatus.completed) matchDue = true;
        }
      }
      
      if (!matchDue) return false;
    }
    
    return true;
  }).toList();
}

List<Task> sortTasks(List<Task> tasks, TaskSort sort) {
  final list = List<Task>.from(tasks);
  list.sort((a, b) {
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;

    switch (sort) {
      case TaskSort.manual:
        return a.sortOrder.compareTo(b.sortOrder);
      case TaskSort.dueDateAsc:
        if (a.dueAt == null && b.dueAt == null) return a.sortOrder.compareTo(b.sortOrder);
        if (a.dueAt == null) return 1;
        if (b.dueAt == null) return -1;
        final res = a.dueAt!.compareTo(b.dueAt!);
        return res != 0 ? res : a.sortOrder.compareTo(b.sortOrder);
      case TaskSort.priorityDesc:
        final res = b.priority.index.compareTo(a.priority.index);
        return res != 0 ? res : a.sortOrder.compareTo(b.sortOrder);
      case TaskSort.createdDesc:
        final res = b.createdAt.compareTo(a.createdAt);
        return res != 0 ? res : a.sortOrder.compareTo(b.sortOrder);
      case TaskSort.titleAsc:
        final res = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        return res != 0 ? res : a.sortOrder.compareTo(b.sortOrder);
      case TaskSort.dueDateDesc:
        if (a.dueAt == null && b.dueAt == null) return a.sortOrder.compareTo(b.sortOrder);
        if (a.dueAt == null) return 1;
        if (b.dueAt == null) return -1;
        final res = b.dueAt!.compareTo(a.dueAt!);
        return res != 0 ? res : a.sortOrder.compareTo(b.sortOrder);
    }
  });
  return list;
}

List<Task> applyQuery(List<Task> tasks, SearchQuery query) {
  var result = searchTasks(tasks, query.text);
  result = filterTasks(result, query.filter);
  return sortTasks(result, query.sort);
}
