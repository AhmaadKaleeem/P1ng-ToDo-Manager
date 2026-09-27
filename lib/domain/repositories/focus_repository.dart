import 'package:todow/domain/models/focus_session.dart';

abstract class FocusRepository {
  Future<FocusSession?> getActiveSession();
  Future<FocusSession> saveSession(FocusSession session);
  Future<List<FocusSession>> getHistory({int limit = 20});
}
