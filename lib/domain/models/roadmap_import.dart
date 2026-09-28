class RoadmapImportRow {
  const RoadmapImportRow({
    required this.roadmapTitle,
    required this.topicTitle,
    required this.topicOrder,
    required this.taskTitle,
    this.roadmapDescription,
    this.topicDescription,
    this.topicStatus = 'pending',
    this.taskDescription,
    this.dueDate,
    this.dueTime,
    this.priority = 'none',
    this.taskStatus = 'active',
    this.reminder = 'none',
  });

  final String roadmapTitle;
  final String? roadmapDescription;
  final String topicTitle;
  final String? topicDescription;
  final int topicOrder;
  final String topicStatus;
  final String taskTitle;
  final String? taskDescription;
  final String? dueDate;
  final String? dueTime;
  final String priority;
  final String taskStatus;
  final String reminder;
}

class RoadmapImportDraft {
  const RoadmapImportDraft({required this.rows, this.errors = const []});

  final List<RoadmapImportRow> rows;
  final List<String> errors;

  bool get isValid => errors.isEmpty && rows.isNotEmpty;
  String get title => rows.isEmpty ? '' : rows.first.roadmapTitle;
  int get topicCount => rows.map((row) => '${row.topicOrder}:${row.topicTitle}').toSet().length;
}
