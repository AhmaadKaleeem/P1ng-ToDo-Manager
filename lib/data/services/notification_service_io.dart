import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

typedef NotificationTapHandler = void Function(String? payload, String? action);

class NotificationServiceImpl implements NotificationService {
  NotificationServiceImpl({this.onAction});

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final NotificationTapHandler? onAction;

  static const channelNormal = 'reminders';
  static const channelConstant = 'constant_reminders';

  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      debugPrint('Device timezone reported: $timeZoneName');
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Timezone set to: ${tz.local.name}');
    } catch (e) {
      debugPrint('Could not initialize timezone: $e — falling back to Asia/Karachi (+05:00)');
      // Use Asia/Karachi as the hardcoded fallback for UTC+5 devices
      // so scheduled alarms fire at the correct local time instead of 5h early.
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        onAction?.call(response.payload, response.actionId);
      },
    );
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(channelNormal, 'Reminders',
            description: 'Task reminder notifications',
            importance: Importance.high),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(channelConstant, 'Constant Reminders',
            description: 'Persistent reminders until task is completed',
            importance: Importance.max),
      );
    }
  }

  @override
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final notificationsAllowed =
          await android?.requestNotificationsPermission() ?? false;
      if (!notificationsAllowed) return false;
      if (await android?.canScheduleExactNotifications() == false) {
        await android?.requestExactAlarmsPermission();
      }
      return true;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }
    return true;
  }

  @override
  Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  @override
  Future<int> scheduleTaskReminder({
    required Task task,
    required DateTime scheduledAt,
    required int notificationId,
    required bool isConstant,
    String? label,
    bool ringAsAlarm = false,
  }) async {
    final channel = isConstant ? channelConstant : channelNormal;

    // Single source of truth for what the notification says.
    // Collapsed (ticker) and expanded views both use title + body.
    final title = isConstant ? 'Constant Reminder' : 'Reminder';
    final body  = label == null ? task.title : '${task.title} — $label';

    // BigText expansion: show the task description when available,
    // otherwise fall back to body so it is always informative.
    final expandedText = task.description.isNotEmpty
        ? '${task.title}\n\n${task.description}'
        : body;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        isConstant ? 'Constant Reminders' : 'Reminders',
        channelDescription: 'Task reminder notifications',
        importance: isConstant ? Importance.max : Importance.high,
        priority: isConstant ? Priority.max : Priority.high,
        ongoing: isConstant,
        autoCancel: !isConstant,
        fullScreenIntent: ringAsAlarm,
        additionalFlags: ringAsAlarm ? Int32List.fromList(<int>[4]) : null,
        // Brand accent colour (orange) applied to the notification icon
        color: const Color(0xFFF97316),
        styleInformation: BigTextStyleInformation(
          expandedText,
          contentTitle: body,
          summaryText: label,
          htmlFormatContent: false,
          htmlFormatContentTitle: false,
        ),
        subText: isConstant ? 'Constant reminder' : 'Reminder',
        actions: const [
          AndroidNotificationAction('complete', 'Complete',
              showsUserInterface: true),
          AndroidNotificationAction('snooze', 'Snooze 15m',
              showsUserInterface: true),
          AndroidNotificationAction('open', 'Open',
              showsUserInterface: true),
        ],
      ),
      iOS: const DarwinNotificationDetails(
          presentAlert: true, presentSound: true),
    );

    debugPrint(
      'Scheduling notification #$notificationId "$title" for '
      '${scheduledAt.toIso8601String()} '
      '(now: ${DateTime.now().toIso8601String()}, tz: ${tz.local.name})',
    );

    if (scheduledAt.isBefore(DateTime.now())) {
      // Past/overdue — fire immediately
      await _plugin.show(notificationId, title, body, details,
          payload: task.id);
    } else {
      final tzScheduled = tz.TZDateTime.from(scheduledAt, tz.local);
      try {
        await _plugin.zonedSchedule(
          notificationId,
          title,
          body,
          tzScheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: task.id,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('Exact alarm unavailable, falling back to inexact: $e');
        await _plugin.zonedSchedule(
          notificationId,
          title,
          body,
          tzScheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: task.id,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
    return notificationId;
  }

  @override
  Future<void> cancelNotification(int notificationId) =>
      _plugin.cancel(notificationId);

  @override
  Future<void> cancelAllForTask(
      String taskId, List<int> notificationIds) async {
    for (final id in notificationIds) {
      await cancelNotification(id);
    }
  }

  @override
  Future<void> scheduleConstantFollowUp({
    required Task task,
    required int notificationId,
    Duration interval = const Duration(minutes: 15),
  }) =>
      scheduleTaskReminder(
        task: task,
        scheduledAt: DateTime.now().add(interval),
        notificationId: notificationId,
        isConstant: true,
        label: 'Still pending',
        ringAsAlarm: task.reminderPlan.ringAsAlarm,
      );
}
