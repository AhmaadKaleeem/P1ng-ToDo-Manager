import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'package:todow/domain/models/roadmap_import.dart';
import 'package:todow/presentation/controllers/roadmap_controller.dart';
import 'package:todow/presentation/screens/roadmap_detail_screen.dart';

class RoadmapImportScreen extends StatefulWidget {
  const RoadmapImportScreen({super.key});

  @override
  State<RoadmapImportScreen> createState() => _RoadmapImportScreenState();
}

class _RoadmapImportScreenState extends State<RoadmapImportScreen> {
  RoadmapImportDraft? _draft;
  bool _loading = false;
  String? _fileName;

  Future<void> _chooseFile(String extension) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [extension],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file?.bytes == null) {
      return;
    }
    setState(() => _loading = true);
    final draft = _RoadmapImportParser.parse(file!);
    if (mounted) {
      setState(() {
        _draft = draft;
        _fileName = file.name;
        _loading = false;
      });
    }
  }

  Future<void> _import() async {
    final draft = _draft;
    if (draft == null || !draft.isValid) return;
    setState(() => _loading = true);
    final roadmap = await context.read<RoadmapController>().importDraft(draft);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RoadmapDetailScreen(roadmap: roadmap)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          title: const Text('Import Roadmap', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Bring an existing plan into Todow.', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              if (_fileName == null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : () => _chooseFile('csv'),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('CSV'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.divider)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : () => _chooseFile('xlsx'),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Excel'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.divider)),
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _loading ? null : () => _chooseFile('csv'),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(_fileName!),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.divider)),
                ),
              const SizedBox(height: 16),
              if (_loading) const LinearProgressIndicator(color: AppColors.action),
              if (_draft != null) _ImportPreview(draft: _draft!),
              const Spacer(),
              if (_draft?.isValid ?? false)
                ElevatedButton(
                  onPressed: _loading ? null : _import,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.action, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(56)),
                  child: const Text('Import Roadmap'),
                ),
            ],
          ),
        ),
      );
}

class _ImportPreview extends StatelessWidget {
  const _ImportPreview({required this.draft});
  final RoadmapImportDraft draft;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(draft.isValid ? draft.title : 'Fix import errors', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Text('${draft.topicCount} Topics · ${draft.rows.length} Tasks', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              if (draft.errors.isEmpty)
                const Text('Ready to import', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.action))
              else
                for (final error in draft.errors) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(error, style: const TextStyle(color: AppColors.alert))),
            ],
          ),
        ),
      );
}

class _RoadmapImportParser {
  static const _headers = [
    'roadmap_title', 'roadmap_description', 'topic_title', 'topic_description',
    'topic_order', 'topic_status', 'task_title', 'task_description', 'due_date',
    'due_time', 'priority', 'task_status', 'reminder',
  ];

  static RoadmapImportDraft parse(PlatformFile file) {
    try {
      final rows = file.extension?.toLowerCase() == 'xlsx'
          ? _xlsxRows(file.bytes!)
          : _csvRows(utf8.decode(file.bytes!));
      return _normalize(rows);
    } catch (_) {
      return const RoadmapImportDraft(rows: [], errors: ['Could not read this file. Use the Roadmap CSV or Excel template.']);
    }
  }

  static RoadmapImportDraft _normalize(List<List<String>> source) {
    if (source.isEmpty) return const RoadmapImportDraft(rows: [], errors: ['The file is empty.']);
    final columns = {for (var i = 0; i < source.first.length; i++) source.first[i].trim().toLowerCase(): i};
    final missing = _headers.where((header) => !columns.containsKey(header)).toList();
    if (missing.isNotEmpty) return RoadmapImportDraft(rows: const [], errors: ['Missing columns: ${missing.join(', ')}']);
    String value(List<String> row, String header) {
      final index = columns[header]!;
      return index < row.length ? row[index].trim() : '';
    }
    final errors = <String>[];
    final rows = <RoadmapImportRow>[];
    String? title;
    for (var i = 1; i < source.length; i++) {
      final row = source[i];
      if (row.every((value) => value.trim().isEmpty)) continue;
      final roadmapTitle = value(row, 'roadmap_title');
      final topicTitle = value(row, 'topic_title');
      final taskTitle = value(row, 'task_title');
      final topicOrder = int.tryParse(value(row, 'topic_order'));
      final topicStatus = value(row, 'topic_status').toLowerCase();
      final priority = value(row, 'priority').toLowerCase();
      var taskStatus = value(row, 'task_status').toLowerCase();
      final dueDate = value(row, 'due_date');
      final dueTime = value(row, 'due_time');
      final reminder = value(row, 'reminder').toLowerCase();
      final line = i + 1;
      if (roadmapTitle.isEmpty) errors.add('Row $line: Roadmap title is required.');
      if (topicTitle.isEmpty) errors.add('Row $line: Topic title is required.');
      if (taskTitle.isEmpty) errors.add('Row $line: Task title is required.');
      if (topicOrder == null || topicOrder < 1) errors.add('Row $line: Topic order must be a positive number.');
      if (!{'pending', 'active', 'completed'}.contains(topicStatus)) errors.add('Row $line: Invalid Topic status.');
      if (!{'none', 'low', 'medium', 'high', 'critical'}.contains(priority)) errors.add('Row $line: Invalid priority.');
      if (taskStatus == 'pending') taskStatus = 'active';
      if (!{'inbox', 'active', 'completed', 'archived'}.contains(taskStatus)) errors.add('Row $line: Invalid task status.');
      if (dueDate.isNotEmpty && DateTime.tryParse(dueDate) == null) errors.add('Row $line: Invalid date.');
      if (dueTime.isNotEmpty && !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(dueTime)) errors.add('Row $line: Invalid time.');
      if (!{'none', 'normal', 'assignment', 'critical'}.contains(reminder)) errors.add('Row $line: Invalid reminder.');
      title ??= roadmapTitle;
      if (roadmapTitle.isNotEmpty && title != roadmapTitle) errors.add('Row $line: Only one Roadmap can be imported at a time.');
      if (topicOrder != null) rows.add(RoadmapImportRow(roadmapTitle: roadmapTitle, roadmapDescription: value(row, 'roadmap_description'), topicTitle: topicTitle, topicDescription: value(row, 'topic_description'), topicOrder: topicOrder, topicStatus: topicStatus, taskTitle: taskTitle, taskDescription: value(row, 'task_description'), dueDate: dueDate, dueTime: dueTime, priority: priority, taskStatus: taskStatus, reminder: reminder));
    }
    return RoadmapImportDraft(rows: rows, errors: errors);
  }

  static List<List<String>> _csvRows(String input) {
    final rows = <List<String>>[]; final row = <String>[]; final field = StringBuffer(); var quoted = false;
    for (var i = 0; i < input.length; i++) { final char = input[i]; if (char == '"') { if (quoted && i + 1 < input.length && input[i + 1] == '"') { field.write(char); i++; } else { quoted = !quoted; } } else if (char == ',' && !quoted) { row.add(field.toString()); field.clear(); } else if ((char == '\n' || char == '\r') && !quoted) { if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++; row.add(field.toString()); field.clear(); rows.add(List.of(row)); row.clear(); } else { field.write(char); } }
    if (field.isNotEmpty || row.isNotEmpty) { row.add(field.toString()); rows.add(row); }
    return rows;
  }

  static List<List<String>> _xlsxRows(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    String text(String name) => utf8.decode(archive.findFile(name)!.content as List<int>);
    final shared = archive.findFile('xl/sharedStrings.xml') == null ? <String>[] : RegExp(r'<t[^>]*>(.*?)</t>', dotAll: true).allMatches(text('xl/sharedStrings.xml')).map((match) => _decode(match.group(1)!)).toList();
    final sheet = archive.files.firstWhere((file) => file.name.startsWith('xl/worksheets/') && file.name.endsWith('.xml'));
    final rows = <List<String>>[];
    for (final row in RegExp(r'<row[^>]*>(.*?)</row>', dotAll: true).allMatches(utf8.decode(sheet.content as List<int>))) {
      final values = <int, String>{};
      for (final cell in RegExp(r'<c[^>]*r="([A-Z]+)\d+"[^>]*>(.*?)</c>', dotAll: true).allMatches(row.group(1)!)) {
        final column = _column(cell.group(1)!); final xml = cell.group(2)!;
        final value = RegExp(r'<v>(.*?)</v>', dotAll: true).firstMatch(xml)?.group(1) ?? RegExp(r'<t[^>]*>(.*?)</t>', dotAll: true).firstMatch(xml)?.group(1) ?? '';
        values[column] = xml.contains('t="s"') && int.tryParse(value) != null ? shared[int.parse(value)] : _decode(value);
      }
      rows.add([for (var i = 0; i <= (values.keys.isEmpty ? 0 : values.keys.reduce((a, b) => a > b ? a : b)); i++) values[i] ?? '']);
    }
    return rows;
  }

  static int _column(String letters) { var value = 0; for (final code in letters.codeUnits) { value = value * 26 + code - 64; } return value - 1; }
  static String _decode(String value) => value.replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"');
}
