import 'package:flutter/foundation.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/timetable_entry.dart';
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

  List<TimetableEntry> forDay(Weekday weekday) =>
      _entries.where((entry) => entry.weekday == weekday).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  Future<void> add({
    required String courseName,
    required String instructor,
    required Weekday weekday,
    required DateTime startTime,
    required DateTime endTime,
    String? room,
  }) async {
    if (courseName.trim().isEmpty) {
      throw TimetableValidationException('Course name is required.');
    }
    if (!endTime.isAfter(startTime)) {
      throw TimetableValidationException('End time must be after start time.');
    }
    await _repository.create(
      TimetableEntry(
        id: _uuid.v4(),
        courseName: courseName.trim(),
        instructor: instructor.trim(),
        weekday: weekday,
        startTime: startTime,
        endTime: endTime,
        room: room?.trim().isEmpty == true ? null : room?.trim(),
      ),
    );
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }
}

class TimetableValidationException implements Exception {
  TimetableValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}
