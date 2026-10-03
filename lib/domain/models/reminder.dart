import 'package:todow/domain/models/enums.dart';

class ReminderOffset {
  const ReminderOffset({
    required this.days,
    required this.hours,
    required this.minutes,
    this.atDeadline = false,
  });

  final int days;
  final int hours;
  final int minutes;
  final bool atDeadline;

  String get label {
    if (atDeadline) return 'At deadline';
    final parts = <String>[];
    if (days > 0) parts.add('$days day${days == 1 ? '' : 's'} before');
    if (hours > 0) parts.add('$hours hour${hours == 1 ? '' : 's'} before');
    if (minutes > 0) {
      parts.add('$minutes minute${minutes == 1 ? '' : 's'} before');
    }
    return parts.isEmpty ? 'Custom' : parts.join(', ');
  }

  Map<String, Object?> toJson() => {
        'days': days,
        'hours': hours,
        'minutes': minutes,
        'atDeadline': atDeadline,
      };

  factory ReminderOffset.fromJson(Map<String, Object?> json) => ReminderOffset(
        days: json['days']! as int,
        hours: json['hours']! as int,
        minutes: json['minutes']! as int,
        atDeadline: json['atDeadline'] as bool? ?? false,
      );
}

class ReminderPlan {
  const ReminderPlan({
    required this.preset,
    required this.offsets,
    required this.constantReminder,
    this.customOffsets = const [],
    this.dailyReminderMinutes,
    this.flexibleReminder = false,
    this.ringAsAlarm = false,
  });

  final ReminderPreset preset;
  final List<ReminderOffset> offsets;
  final List<ReminderOffset> customOffsets;
  final bool constantReminder;
  /// Minutes since midnight for daily repeating reminder (null = off).
  final int? dailyReminderMinutes;
  final bool flexibleReminder;
  final bool ringAsAlarm;

  List<ReminderOffset> get allOffsets => [...offsets, ...customOffsets];

  ReminderPlan copyWith({
    ReminderPreset? preset,
    List<ReminderOffset>? offsets,
    List<ReminderOffset>? customOffsets,
    bool? constantReminder,
    int? dailyReminderMinutes,
    bool clearDailyReminder = false,
    bool? flexibleReminder,
    bool? ringAsAlarm,
  }) {
    return ReminderPlan(
      preset: preset ?? this.preset,
      offsets: offsets ?? this.offsets,
      customOffsets: customOffsets ?? this.customOffsets,
      constantReminder: constantReminder ?? this.constantReminder,
      dailyReminderMinutes: clearDailyReminder ? null : (dailyReminderMinutes ?? this.dailyReminderMinutes),
      flexibleReminder: flexibleReminder ?? this.flexibleReminder,
      ringAsAlarm: ringAsAlarm ?? this.ringAsAlarm,
    );
  }

  Map<String, Object?> toJson() => {
        'preset': preset.name,
        'offsets': offsets.map((o) => o.toJson()).toList(),
        'customOffsets': customOffsets.map((o) => o.toJson()).toList(),
        'constantReminder': constantReminder,
        'dailyReminderMinutes': dailyReminderMinutes,
        'flexibleReminder': flexibleReminder,
        'ringAsAlarm': ringAsAlarm,
      };

  factory ReminderPlan.fromJson(Map<String, Object?> json) => ReminderPlan(
        preset: ReminderPreset.values.byName(json['preset']! as String),
        offsets: (json['offsets'] as List)
            .map((e) =>
                ReminderOffset.fromJson(Map<String, Object?>.from(e as Map)))
            .toList(),
        customOffsets: (json['customOffsets'] as List? ?? [])
            .map((e) =>
                ReminderOffset.fromJson(Map<String, Object?>.from(e as Map)))
            .toList(),
        constantReminder: json['constantReminder'] as bool? ?? false,
        dailyReminderMinutes: json['dailyReminderMinutes'] as int?,
        flexibleReminder: json['flexibleReminder'] as bool? ?? false,
        ringAsAlarm: json['ringAsAlarm'] as bool? ?? false,
      );
}

class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.taskId,
    required this.scheduledAt,
    required this.status,
    required this.kind,
    this.snoozedUntil,
    this.notificationId,
    this.label,
  });

  final String id;
  final String taskId;
  final DateTime scheduledAt;
  final ReminderStatus status;
  final ReminderKind kind;
  final DateTime? snoozedUntil;
  final int? notificationId;
  final String? label;

  bool get isActive =>
      status == ReminderStatus.pending || status == ReminderStatus.snoozed;

  ScheduledReminder copyWith({
    DateTime? scheduledAt,
    ReminderStatus? status,
    DateTime? snoozedUntil,
    bool clearSnoozedUntil = false,
    int? notificationId,
    String? label,
  }) {
    return ScheduledReminder(
      id: id,
      taskId: taskId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      kind: kind,
      snoozedUntil: clearSnoozedUntil ? null : (snoozedUntil ?? this.snoozedUntil),
      notificationId: notificationId ?? this.notificationId,
      label: label ?? this.label,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'task_id': taskId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': status.name,
        'kind': kind.name,
        'snoozed_until': snoozedUntil?.toIso8601String(),
        'notification_id': notificationId,
        'label': label,
      };

  factory ScheduledReminder.fromMap(Map<String, Object?> map) =>
      ScheduledReminder(
        id: map['id']! as String,
        taskId: map['task_id']! as String,
        scheduledAt: DateTime.parse(map['scheduled_at']! as String),
        status: ReminderStatus.values.byName(map['status']! as String),
        kind: ReminderKind.values.byName(map['kind']! as String),
        snoozedUntil: map['snoozed_until'] != null
            ? DateTime.parse(map['snoozed_until']! as String)
            : null,
        notificationId: map['notification_id'] as int?,
        label: map['label'] as String?,
      );
}
