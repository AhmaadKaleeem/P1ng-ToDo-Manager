import 'package:p1ng_todo_manager/domain/models/enums.dart';
import 'package:p1ng_todo_manager/domain/models/focus_session.dart';
import 'package:p1ng_todo_manager/domain/models/task.dart';

abstract class FocusService {
  FocusSession? get currentSession;
  Stream<FocusSession?> get sessionStream;

  Future<FocusSession> startSession({
    Task? task,
    required FocusPreset preset,
    Duration? duration,
    List<String>? allowedApps,
  });

  Future<FocusSession> pauseSession();
  Future<FocusSession> resumeSession();
  Future<FocusSession> endSession();
  Future<void> restoreActiveSession();
}
