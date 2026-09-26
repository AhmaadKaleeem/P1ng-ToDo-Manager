import 'package:intl/intl.dart';

abstract final class AppDateFormat {
  static final _time = DateFormat('h:mm a');
  static final _date = DateFormat('EEE, MMM d');
  static final _dateTime = DateFormat('EEE, MMM d · h:mm a');
  static final _monthDay = DateFormat('MMM d');
  static final _weekday = DateFormat('EEEE');
  static String time(DateTime dt) => _time.format(dt);
  static String date(DateTime dt) => _date.format(dt);
  static String dateTime(DateTime dt) => _dateTime.format(dt);
  static String monthDay(DateTime dt) => _monthDay.format(dt);
  static String weekday(DateTime dt) => _weekday.format(dt);
  static String timerDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String dueLabel(DateTime? dueAt) {
    if (dueAt == null) return 'No due date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueAt.year, dueAt.month, dueAt.day);
    final diff = dueDay.difference(today).inDays;
    if (diff == 0) return 'Today · ${time(dueAt)}';
    if (diff == 1) return 'Tomorrow · ${time(dueAt)}';
    if (diff == -1) return 'Yesterday · ${time(dueAt)}';
    if (diff < 0) return 'Overdue · ${dateTime(dueAt)}';
    return dateTime(dueAt);
  }
}
