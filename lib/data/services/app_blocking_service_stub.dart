import 'package:todow/domain/services/app_blocking_service.dart';

/// MVP 0.1 stub — true app blocking requires native Android/iOS integration.
class AppBlockingServiceStub implements AppBlockingService {
  List<String> _allowed = const [];

  @override
  Future<void> disableBlocking() async {}

  @override
  Future<void> enableBlocking() async {}

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<void> setAllowedApps(List<String> packageNames) async {
    _allowed = List.unmodifiable(packageNames);
  }

  List<String> get allowedApps => _allowed;
}
