import 'package:flutter/foundation.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/timetable_entry.dart';
import 'package:todow/domain/models/timetable_import.dart';
import 'package:todow/domain/repositories/timetable_repository.dart';
import 'package:uuid/uuid.dart';

class TimetableController extends ChangeNotifier {
  TimetableController(this._repository);

  final TimetableRepository _repository;
  static const _uuid = Uuid();
  List<TimetableEntry> _entries = [];
  bool _loading = false;
  String? _error;

  List<TimetableEntry> get entries => List.unmodifiable(_entries);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _entries = await _repository.getAll();
    } catch (_) {
      _error = 'Could not load timetable.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<TimetableEntry> entriesFor(TimetableKind scheduleKind) =>
      _entries.where((entry) => entry.scheduleKind == scheduleKind).toList();

  List<TimetableEntry> forDay(
    Weekday weekday, {
    TimetableKind scheduleKind = TimetableKind.university,
  }) =>
      _entries
          .where((entry) =>
              entry.weekday == weekday && entry.scheduleKind == scheduleKind)
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  Future<void> add({
    required String courseName,
    required String instructor,
    required Weekday weekday,
    required DateTime startTime,
    required DateTime endTime,
    TimetableKind scheduleKind = TimetableKind.university,
    String? room,
    DateTime? scheduledDate,
    bool repeatWeekly = true,
    String? taskId,
    String? category,
    int? colorValue,
  }) async {
    _validate(courseName, startTime, endTime);
    await _repository.create(
      TimetableEntry(
        id: _uuid.v4(),
        courseName: courseName.trim(),
        instructor: instructor.trim(),
        weekday: weekday,
        startTime: startTime,
        endTime: endTime,
        scheduleKind: scheduleKind,
        room: room?.trim().isEmpty == true ? null : room?.trim(),
        scheduledDate: scheduledDate,
        repeatWeekly: repeatWeekly,
        taskId: taskId,
        category: category,
        colorValue: colorValue,
      ),
    );
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }

  Future<void> update(TimetableEntry entry) async {
    _validate(entry.courseName, entry.startTime, entry.endTime);
    await _repository.update(entry);
    await load();
  }

  Future<void> importEntries(
    List<TimetableDraftEntry> draft,
    TimetableKind scheduleKind,
  ) async {
    if (draft.isEmpty) {
      throw TimetableValidationException('Add at least one class to import.');
    }
    for (final row in draft) {
      final error = row.validationError;
      if (error != null) throw TimetableValidationException(error);
    }
    final entries =
        draft.map((row) => row.toEntry(scheduleKind, _uuid.v4())).toList();
    await _repository.createMany(entries);
    await load();
  }

  void _validate(String courseName, DateTime startTime, DateTime endTime) {
    if (courseName.trim().isEmpty) {
      throw TimetableValidationException('Course name is required.');
    }
    if (!endTime.isAfter(startTime)) {
      throw TimetableValidationException('End time must be after start time.');
    }
  }
}

class TimetableValidationException implements Exception {
  TimetableValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}
