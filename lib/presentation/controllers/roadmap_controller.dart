import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:todow/domain/models/roadmap.dart';
import 'package:todow/domain/models/roadmap_import.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/reminder.dart';
import 'package:todow/domain/reminders/reminder_presets.dart';
import 'package:todow/domain/repositories/roadmap_repository.dart';

class RoadmapController extends ChangeNotifier {
  RoadmapController({
    required RoadmapRepository roadmapRepo,
    required TopicRepository topicRepo,
    required RoadmapTaskRepository taskRepo,
    required RoadmapImportRepository importRepo,
  })  : _roadmapRepo = roadmapRepo,
        _topicRepo = topicRepo,
        _taskRepo = taskRepo,
        _importRepo = importRepo;

  final RoadmapRepository _roadmapRepo;
  final TopicRepository _topicRepo;
  final RoadmapTaskRepository _taskRepo;
  final RoadmapImportRepository _importRepo;
  static const _uuid = Uuid();

  List<Roadmap> _roadmaps = [];
  bool _loading = false;
  Object? _error;

  List<Roadmap> get roadmaps => _roadmaps;
  bool get loading => _loading;
  Object? get error => _error;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _roadmaps = await _roadmapRepo.getAll();
      _error = null;
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Roadmap> createRoadmap(
      {required String title, String? description, int colorIndex = 0}) async {
    final now = DateTime.now();
    final r = Roadmap(
        id: _uuid.v4(),
        title: title,
        description: description,
        colorIndex: colorIndex,
        orderIndex: _roadmaps.length,
        createdAt: now,
        updatedAt: now);
    await _roadmapRepo.create(r);
    _roadmaps = [..._roadmaps, r];
    notifyListeners();
    return r;
  }

  Future<void> updateRoadmap(Roadmap roadmap) async {
    await _roadmapRepo.update(roadmap);
    _roadmaps = [for (final r in _roadmaps) r.id == roadmap.id ? roadmap : r];
    notifyListeners();
  }

  Future<void> deleteRoadmap(String id) async {
    await _roadmapRepo.delete(id);
    _roadmaps = _roadmaps.where((r) => r.id != id).toList();
    notifyListeners();
  }

  Future<void> reorderRoadmaps(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final reordered = [..._roadmaps];
    final roadmap = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, roadmap);
    await _roadmapRepo.reorder(reordered);
    _roadmaps = [
      for (var i = 0; i < reordered.length; i++)
        reordered[i].copyWith(orderIndex: i)
    ];
    notifyListeners();
  }

  Future<List<Topic>> getTopics(String roadmapId) =>
      _topicRepo.getByRoadmapId(roadmapId);
  Future<Topic?> getTopic(String id) => _topicRepo.getById(id);
  Future<Roadmap?> getRoadmap(String id) => _roadmapRepo.getById(id);

  Future<Topic> createTopic(
      {required String roadmapId,
      required String title,
      String? description,
      required int orderIndex}) async {
    final now = DateTime.now();
    final t = Topic(
        id: _uuid.v4(),
        roadmapId: roadmapId,
        title: title,
        description: description,
        orderIndex: orderIndex,
        status: TopicStatus.pending,
        createdAt: now,
        updatedAt: now);
    await _topicRepo.create(t);
    return t;
  }

  Future<void> updateTopic(Topic topic) => _topicRepo.update(topic);
  Future<void> deleteTopic(String id) => _topicRepo.delete(id);

  Future<List<Task>> getTasksByTopic(String topicId) =>
      _taskRepo.getByTopicId(topicId);
  Future<List<Task>> getTasksByRoadmap(String roadmapId,
          {DateTime? from, DateTime? to}) =>
      _taskRepo.getByRoadmapId(roadmapId, from: from, to: to);

  Future<Roadmap> importDraft(RoadmapImportDraft draft) async {
    final now = DateTime.now();
    final roadmap = Roadmap(
      id: _uuid.v4(),
      title: draft.title,
      description: draft.rows.first.roadmapDescription,
      colorIndex: 0,
      orderIndex: _roadmaps.length,
      createdAt: now,
      updatedAt: now,
    );
    final topicByKey = <String, Topic>{};
    for (final row in draft.rows) {
      final key = '${row.topicOrder}:${row.topicTitle}';
      topicByKey.putIfAbsent(
        key,
        () => Topic(
          id: _uuid.v4(),
          roadmapId: roadmap.id,
          title: row.topicTitle,
          description: row.topicDescription,
          orderIndex: row.topicOrder - 1,
          status: TopicStatus.values.byName(row.topicStatus),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    final tasks = [
      for (final row in draft.rows)
        Task(
          id: _uuid.v4(),
          title: row.taskTitle,
          description: row.taskDescription ?? '',
          status: TaskStatus.values.byName(row.taskStatus),
          priority: TaskPriority.values.byName(row.priority),
          createdAt: now,
          updatedAt: now,
          dueAt: _dueAt(row.dueDate, row.dueTime),
          topicId: topicByKey['${row.topicOrder}:${row.topicTitle}']!.id,
          reminderPlan: ReminderPlan(
            preset: _reminderPreset(row.reminder),
            offsets: row.reminder == 'none'
                ? const <ReminderOffset>[]
                : ReminderPresets.forPreset(_reminderPreset(row.reminder)),
            constantReminder: false,
          ),
          sourceType: TaskSourceType.local,
        ),
    ];
    await _importRepo.importAll(
        roadmap: roadmap, topics: topicByKey.values.toList(), tasks: tasks);
    _roadmaps = [..._roadmaps, roadmap];
    notifyListeners();
    return roadmap;
  }

  DateTime? _dueAt(String? date, String? time) {
    if (date == null || date.isEmpty) return null;
    final selectedTime = time == null || time.isEmpty ? '00:00' : time;
    return DateTime.tryParse('${date}T$selectedTime');
  }

  ReminderPreset _reminderPreset(String reminder) => switch (reminder) {
        'assignment' => ReminderPreset.assignment,
        'critical' => ReminderPreset.critical,
        'none' => ReminderPreset.custom,
        _ => ReminderPreset.normal,
      };
}
