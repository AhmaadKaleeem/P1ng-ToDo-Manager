import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/timetable_import.dart';
import 'package:xml/xml.dart';

class TimetableImportParser {
  const TimetableImportParser();

  TimetableImportDraft parseFile({
    required String name,
    required Uint8List bytes,
  }) {
    try {
      final rows = name.toLowerCase().endsWith('.xlsx')
          ? _excelRows(bytes)
          : _csvRows(utf8.decode(bytes, allowMalformed: true));
      return _draftRows(rows);
    } catch (_) {
      return const TimetableImportDraft(
        rows: [],
        errors: [
          'This file could not be read. Check the template and try again.'
        ],
      );
    }
  }

  TimetableImportDraft parseOcr(RecognizedText recognizedText) {
    final rows = <TimetableDraftEntry>[];
    final dayPattern = RegExp(
      r'\b(mon(?:day)?|tue(?:sday)?|wed(?:nesday)?|thu(?:rsday)?|fri(?:day)?|sat(?:urday)?|sun(?:day)?)\b',
      caseSensitive: false,
    );
    final timeRangePattern = RegExp(
      r'(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\s*(?:-|–|—|to)\s*(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)',
      caseSensitive: false,
    );

    final lines = <TextLine>[];
    for (final block in recognizedText.blocks) {
      lines.addAll(block.lines);
    }
    
    // Group lines horizontally if they are roughly on the same vertical level.
    final rowStrings = <String>[];
    if (lines.isNotEmpty) {
      // Sort primarily by Y coordinate
      lines.sort((a, b) => a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy));

      var currentRow = [lines.first];
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i];
        final avgY = currentRow.map((e) => e.boundingBox.center.dy).reduce((a, b) => a + b) / currentRow.length;
        if ((line.boundingBox.center.dy - avgY).abs() < 25) { // Vertical tolerance
          currentRow.add(line);
        } else {
          currentRow.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
          rowStrings.add(currentRow.map((e) => e.text).join(' '));
          currentRow = [line];
        }
      }
      if (currentRow.isNotEmpty) {
        currentRow.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
        rowStrings.add(currentRow.map((e) => e.text).join(' '));
      }
    }

    for (final rawLine in rowStrings) {
      final line = rawLine.trim();
      final dayMatch = dayPattern.firstMatch(line);
      final timeMatch = timeRangePattern.firstMatch(line);
      if (dayMatch == null && timeMatch == null) continue;
      final day = dayMatch == null ? null : _parseDay(dayMatch.group(1)!);
      final start = timeMatch == null ? null : _parseTime(timeMatch.group(1)!);
      var end = timeMatch == null ? null : _parseTime(timeMatch.group(2)!);
      if (start != null && end != null && !end.isAfter(start)) {
        end = end.add(const Duration(hours: 12));
      }

      var details =
          line.replaceAll(dayPattern, ' ').replaceAll(timeRangePattern, ' ');
      String instructor = '';
      final labeledInstructor = RegExp(
        r'\b(?:instructor|teacher|professor)\s*[:\-]?\s*([^,;|]+)',
        caseSensitive: false,
      ).firstMatch(details);
      final titledInstructor =
          RegExp(r'\b(?:Dr|Prof)\.?\s+[A-Z][\w-]+(?:\s+[A-Z][\w-]+)?')
              .firstMatch(details);
      final instructorMatch = labeledInstructor ?? titledInstructor;
      if (instructorMatch != null) {
        instructor =
            instructorMatch.group(labeledInstructor != null ? 1 : 0)!.trim();
        details = details.replaceRange(
            instructorMatch.start, instructorMatch.end, ' ');
      }

      String room = '';
      final roomMatch = RegExp(
        r'\b(?:room|lab|venue)\s*[#:.-]?\s*[A-Z0-9][A-Z0-9 -]*',
        caseSensitive: false,
      ).firstMatch(details);
      if (roomMatch != null) {
        room = roomMatch.group(0)!.trim();
        details = details.replaceRange(roomMatch.start, roomMatch.end, ' ');
      }
      final course = details
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'^[\s:|,.-]+|[\s:|,.-]+$'), '')
          .trim();
      rows.add(TimetableDraftEntry(
        courseName: course,
        instructor: instructor,
        room: room,
        weekday: day,
        startTime: start,
        endTime: end,
      ));
    }
    return TimetableImportDraft(
      rows: rows,
      errors: rows.isEmpty
          ? const ['No class rows were recognized in this image.']
          : const [],
    );
  }

  TimetableImportDraft _draftRows(List<List<String>> source) {
    if (source.isEmpty) {
      return const TimetableImportDraft(
          rows: [], errors: ['The file has no class rows.']);
    }
    final headers = {
      for (var i = 0; i < source.first.length; i++)
        _normalizeHeader(source.first[i]): i,
    };
    final courseColumn = _column(headers, ['course', 'course_name', 'class']);
    final dayColumn = _column(headers, ['day', 'weekday']);
    final startColumn = _column(headers, ['start_time', 'start']);
    final endColumn = _column(headers, ['end_time', 'end']);
    if (courseColumn == null ||
        dayColumn == null ||
        startColumn == null ||
        endColumn == null) {
      return const TimetableImportDraft(
        rows: [],
        errors: ['Required columns are course, day, start_time, and end_time.'],
      );
    }

    final rows = <TimetableDraftEntry>[];
    final errors = <String>[];
    String value(List<String> row, List<String> names) {
      final index = _column(headers, names);
      return index == null || index >= row.length ? '' : row[index].trim();
    }

    for (var i = 1; i < source.length; i++) {
      final row = source[i];
      if (row.every((cell) => cell.trim().isEmpty)) continue;
      final dayRaw = value(row, ['day', 'weekday']);
      final startRaw = value(row, ['start_time', 'start']);
      final endRaw = value(row, ['end_time', 'end']);
      final draft = TimetableDraftEntry(
        courseName: value(row, ['course', 'course_name', 'class']),
        instructor: value(row, ['instructor', 'teacher', 'professor']),
        room: value(row, ['room', 'lab', 'venue']),
        weekday: _parseDay(dayRaw),
        startTime: _parseTime(startRaw),
        endTime: _parseTime(endRaw),
      );
      final error = draft.validationError;
      if (error != null) {
        errors.add('Row ${i + 1}: $error');
      }
      rows.add(draft);
    }
    if (rows.isEmpty && errors.isEmpty) {
      errors.add('The file has no class rows.');
    }
    return TimetableImportDraft(rows: rows, errors: errors);
  }

  List<List<String>> _csvRows(String text) {
    final rows = <List<String>>[];
    final row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == '"') {
        if (quoted && i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (!quoted && char == ',') {
        row.add(field.toString());
        field.clear();
      } else if (!quoted && (char == '\n' || char == '\r')) {
        if (char == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        row.add(field.toString());
        field.clear();
        rows.add(List.of(row));
        row.clear();
      } else {
        field.write(char);
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }

  List<List<String>> _excelRows(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    XmlDocument xml(String name) => XmlDocument.parse(
        utf8.decode(archive.findFile(name)!.content as List<int>));
    final sharedFile = archive.findFile('xl/sharedStrings.xml');
    final shared = sharedFile == null
        ? <String>[]
        : XmlDocument.parse(utf8.decode(sharedFile.content as List<int>))
            .findAllElements('si')
            .map((item) =>
                item.findAllElements('t').map((text) => text.innerText).join())
            .toList();
    final sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
    if (sheetFile == null) throw const FormatException('Worksheet is missing.');
    final sheet = xml(sheetFile.name);
    return sheet
        .findAllElements('row')
        .map((row) {
          final values = <int, String>{};
          for (final cell in row.findAllElements('c')) {
            final column = _excelColumn(cell.getAttribute('r') ?? '');
            final value = cell.getElement('v')?.innerText ??
                cell
                    .getElement('is')
                    ?.findAllElements('t')
                    .map((t) => t.innerText)
                    .join() ??
                '';
            final resolved =
                cell.getAttribute('t') == 's' && int.tryParse(value) != null
                    ? shared[int.parse(value)]
                    : value;
            values[column] = resolved;
          }
          if (values.isEmpty) return <String>[];
          final max = values.keys.reduce((a, b) => a > b ? a : b);
          return List.generate(max + 1, (index) => values[index] ?? '');
        })
        .where((row) => row.isNotEmpty)
        .toList();
  }

  String _normalizeHeader(String header) => header
      .trim()
      .replaceFirst('\uFEFF', '')
      .toLowerCase()
      .replaceAll(RegExp(r'[\s-]+'), '_');

  int? _column(Map<String, int> headers, List<String> aliases) {
    for (final alias in aliases) {
      final index = headers[alias];
      if (index != null) return index;
    }
    return null;
  }

  Weekday? _parseDay(String value) {
    final key = value.trim().toLowerCase().replaceAll('.', '');
    if (key.isEmpty) return null;
    for (final day in Weekday.values) {
      if (day.name.startsWith(key) || day.fullLabel.toLowerCase() == key) {
        return day;
      }
    }
    return null;
  }

  DateTime? _parseTime(String value) {
    final raw = value.trim();
    final excelFraction = double.tryParse(raw);
    if (excelFraction != null && excelFraction >= 0 && excelFraction < 1) {
      final minutes = (excelFraction * 24 * 60).round() % (24 * 60);
      final now = DateTime.now();
      return DateTime(
          now.year, now.month, now.day, minutes ~/ 60, minutes.remainder(60));
    }
    final match = RegExp(
      r'^(\d{1,2})(?::|\.)(\d{2})\s*(am|pm)?$|^(\d{1,2})\s*(am|pm)?$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match == null) return null;
    var hour = int.parse(match.group(1) ?? match.group(4)!);
    final minute = int.parse(match.group(2) ?? '0');
    final period = (match.group(3) ?? match.group(5))?.toLowerCase();
    if (hour > 23 || minute > 59 || (period != null && hour > 12)) return null;
    if (period == 'pm' && hour < 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  int _excelColumn(String reference) {
    final letters = RegExp(r'^[A-Z]+', caseSensitive: false)
        .firstMatch(reference.toUpperCase())
        ?.group(0);
    if (letters == null) throw const FormatException('Invalid cell address.');
    var column = 0;
    for (final code in letters.codeUnits) {
      column = column * 26 + code - 64;
    }
    return column - 1;
  }
}
