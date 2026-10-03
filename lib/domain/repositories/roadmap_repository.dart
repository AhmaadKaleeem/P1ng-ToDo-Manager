import 'package:todow/domain/models/roadmap.dart';
import 'package:todow/domain/models/task.dart';

abstract class RoadmapRepository {
  Future<List<Roadmap>> getAll();
  Future<Roadmap?> getById(String id);
  Future<Roadmap> create(Roadmap roadmap);
  Future<Roadmap> update(Roadmap roadmap);
  Future<void> reorder(List<Roadmap> roadmaps);
  Future<void> delete(String id, {bool deleteTasks = false});
}

abstract class TopicRepository {
  Future<List<Topic>> getByRoadmapId(String roadmapId);
  Future<Topic?> getById(String id);
  Future<Topic> create(Topic topic);
  Future<Topic> update(Topic topic);
  Future<void> delete(String id);
}

abstract class RoadmapTaskRepository {
  Future<List<Task>> getByTopicId(String topicId);
  Future<List<Task>> getByRoadmapId(String roadmapId,
      {DateTime? from, DateTime? to});
}

abstract class RoadmapImportRepository {
  Future<void> importAll({
    required Roadmap roadmap,
    required List<Topic> topics,
    required List<Task> tasks,
  });
}
