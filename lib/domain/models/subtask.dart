class Subtask {
  const Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isCompleted,
    required this.sortOrder,
  });

  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int sortOrder;

  Subtask copyWith({
    String? title,
    bool? isCompleted,
    int? sortOrder,
  }) {
    return Subtask(
      id: id,
      taskId: taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'task_id': taskId,
        'title': title,
        'is_completed': isCompleted ? 1 : 0,
        'sort_order': sortOrder,
      };

  factory Subtask.fromMap(Map<String, Object?> map) => Subtask(
        id: map['id']! as String,
        taskId: map['task_id']! as String,
        title: map['title']! as String,
        isCompleted: (map['is_completed'] as int) == 1,
        sortOrder: map['sort_order']! as int,
      );
}
