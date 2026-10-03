import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todow/data/local/app_database.dart';
import 'package:todow/domain/repositories/task_repository.dart';
import 'package:todow/domain/repositories/timetable_repository.dart';
import 'package:todow/domain/repositories/roadmap_repository.dart';
import 'package:todow/domain/repositories/attachment_repository.dart';
import 'package:todow/domain/repositories/focus_repository.dart';
import 'package:todow/domain/services/notification_service.dart';
import 'package:todow/domain/services/focus_service.dart';
import 'package:todow/domain/services/reminder_scheduler.dart';
import 'package:todow/domain/services/file_storage.dart';
import 'package:todow/domain/services/app_blocking_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider is not initialized');
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  throw UnimplementedError('taskRepositoryProvider is not initialized');
});

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  throw UnimplementedError('timetableRepositoryProvider is not initialized');
});

final roadmapRepositoryProvider = Provider<RoadmapRepository>((ref) {
  throw UnimplementedError('roadmapRepositoryProvider is not initialized');
});

final topicRepositoryProvider = Provider<TopicRepository>((ref) {
  throw UnimplementedError('topicRepositoryProvider is not initialized');
});

final roadmapTaskRepositoryProvider = Provider<RoadmapTaskRepository>((ref) {
  throw UnimplementedError('roadmapTaskRepositoryProvider is not initialized');
});

final roadmapImportRepositoryProvider = Provider<RoadmapImportRepository>((ref) {
  throw UnimplementedError('roadmapImportRepositoryProvider is not initialized');
});

final focusRepositoryProvider = Provider<FocusRepository>((ref) {
  throw UnimplementedError('focusRepositoryProvider is not initialized');
});

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  throw UnimplementedError('attachmentRepositoryProvider is not initialized');
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('notificationServiceProvider is not initialized');
});

final focusServiceProvider = Provider<FocusService>((ref) {
  throw UnimplementedError('focusServiceProvider is not initialized');
});

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  throw UnimplementedError('reminderSchedulerProvider is not initialized');
});

final fileStorageProvider = Provider<FileStorage>((ref) {
  throw UnimplementedError('fileStorageProvider is not initialized');
});

final appBlockingServiceProvider = Provider<AppBlockingService>((ref) {
  throw UnimplementedError('appBlockingServiceProvider is not initialized');
});
