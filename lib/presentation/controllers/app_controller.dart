import 'package:flutter/foundation.dart';
import 'package:todow/domain/services/notification_service.dart';

class AppController extends ChangeNotifier {
  AppController(this._notifications);

  final NotificationService _notifications;
  bool _notificationsEnabled = false;

  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> refreshPermissions() async {
    _notificationsEnabled = await _notifications.hasPermissions();
    notifyListeners();
  }

  Future<void> requestNotificationPermissions() async {
    _notificationsEnabled = await _notifications.requestPermissions();
    notifyListeners();
  }
}
