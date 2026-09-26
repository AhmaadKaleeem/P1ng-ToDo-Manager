/// Platform abstraction for future app blocking during focus sessions.
/// MVP 0.1: documents capability; no fake blocking.
abstract class AppBlockingService {
  Future<bool> isSupported();
  Future<void> setAllowedApps(List<String> packageNames);
  Future<void> enableBlocking();
  Future<void> disableBlocking();
}
