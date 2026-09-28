import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'package:todow/domain/models/roadmap.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/presentation/controllers/roadmap_controller.dart';
import 'package:todow/presentation/screens/roadmap_import_screen.dart';
import 'package:todow/presentation/widgets/roadmap_spine_painter.dart';
import 'package:todow/presentation/widgets/topic_card.dart';
import 'package:todow/presentation/widgets/task_time_view.dart';

class RoadmapDetailScreen extends StatefulWidget {
  const RoadmapDetailScreen({required this.roadmap, super.key});
  final Roadmap roadmap;

  @override
  State<RoadmapDetailScreen> createState() => _RoadmapDetailScreenState();
}

class _RoadmapDetailScreenState extends State<RoadmapDetailScreen>
    with SingleTickerProviderStateMixin {
  List<Topic> _topics = [];
  List<Task> _tasks = [];
  bool _loading = true;
  List<GlobalKey> _cardKeys = [];
  final _pathKey = GlobalKey();
  List<Rect> _cardBounds = [];
  late final AnimationController _routeAnimation;

  @override
  void initState() {
    super.initState();
    _routeAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _loadData();
  }

  @override
  void dispose() {
    _routeAnimation.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final ctrl = context.read<RoadmapController>();
    final topics = await ctrl.getTopics(widget.roadmap.id);
    final tasks = await ctrl.getTasksByRoadmap(widget.roadmap.id);
    if (!mounted) return;
    final routeChanged = topics.map((topic) => topic.id).join('|') !=
        _topics.map((topic) => topic.id).join('|');
    setState(() {
      _topics = topics;
      _tasks = tasks;
      _cardKeys = List.generate(topics.length, (_) => GlobalKey());
      if (routeChanged) {
        _cardBounds = [];
        _routeAnimation.value = 0;
      }
      _loading = false;
    });
    _scheduleGeometryUpdate();
  }

  void _scheduleGeometryUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _computeCardBounds());
  }

  void _computeCardBounds() {
    if (!mounted) return;
    final bounds = <Rect>[];
    final pathBox = _pathKey.currentContext?.findRenderObject() as RenderBox?;
    if (pathBox == null) return;

    for (final key in _cardKeys) {
      final ctx = key.currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero, ancestor: pathBox);
        bounds.add(position & box.size);
      }
    }
    if (mounted &&
        bounds.length == _cardKeys.length &&
        !_sameBounds(_cardBounds, bounds)) {
      final firstLayout = _cardBounds.isEmpty;
      setState(() {
        _cardBounds = bounds;
      });
      if (firstLayout || _routeAnimation.isDismissed) {
        _routeAnimation.forward(from: 0);
      }
    }
  }

  bool _sameBounds(List<Rect> a, List<Rect> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _reloadRoadmapTasks() async {
    final tasks = await context
        .read<RoadmapController>()
        .getTasksByRoadmap(widget.roadmap.id);
    if (mounted) setState(() => _tasks = tasks);
  }

  Future<void> _exportRoadmap(bool excel) async {
    try {
      final tasks = await context
          .read<RoadmapController>()
          .getTasksByRoadmap(widget.roadmap.id);
      final rows = <List<String>>[
        const [
          'roadmap_title',
          'roadmap_description',
          'topic_title',
          'topic_description',
          'topic_order',
          'topic_status',
          'task_title',
          'task_description',
          'due_date',
          'due_time',
          'priority',
          'task_status',
          'reminder',
        ],
        for (final task in tasks)
          for (final topic
              in _topics.where((topic) => topic.id == task.topicId))
            [
              widget.roadmap.title,
              widget.roadmap.description ?? '',
              topic.title,
              topic.description ?? '',
              '${topic.orderIndex + 1}',
              topic.status.name,
              task.title,
              task.description,
              task.dueAt == null
                  ? ''
                  : '${task.dueAt!.year.toString().padLeft(4, '0')}-${task.dueAt!.month.toString().padLeft(2, '0')}-${task.dueAt!.day.toString().padLeft(2, '0')}',
              task.dueAt == null
                  ? ''
                  : '${task.dueAt!.hour.toString().padLeft(2, '0')}:${task.dueAt!.minute.toString().padLeft(2, '0')}',
              task.priority.name,
              task.status.name,
              const {'none', 'normal', 'assignment', 'critical'}
                      .contains(task.reminderPlan.preset.name)
                  ? task.reminderPlan.preset.name
                  : 'none',
            ],
      ];
      final extension = excel ? 'xlsx' : 'csv';
      final bytes = excel
          ? _xlsxBytes(rows)
          : Uint8List.fromList(utf8.encode(
              rows.map((row) => row.map(_csvCell).join(',')).join('\r\n'),
            ));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Roadmap',
        fileName: '${widget.roadmap.title}.$extension',
        type: FileType.custom,
        allowedExtensions: [extension],
        bytes: bytes,
      );
      if (!mounted || path == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Roadmap exported as $extension')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not export this roadmap.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.action))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded),
                                color: AppColors.textPrimary,
                                tooltip: 'Back to roadmaps',
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RoadmapImportScreen(),
                                  ),
                                ),
                                icon: const Icon(Icons.upload_file_rounded,
                                    size: 18),
                                label: const Text('Import'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.action,
                                  minimumSize: const Size(48, 48),
                                ),
                              ),
                              const SizedBox(width: 4),
                              PopupMenuButton<bool>(
                                tooltip: 'Export Roadmap',
                                padding: EdgeInsets.zero,
                                onSelected: _exportRoadmap,
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: false,
                                    child: Text('Export CSV'),
                                  ),
                                  PopupMenuItem(
                                    value: true,
                                    child: Text('Export Excel'),
                                  ),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.ios_share_rounded,
                                          size: 18, color: AppColors.action),
                                      const SizedBox(width: 6),
                                      const Text('Export',
                                          style: TextStyle(
                                              color: AppColors.action)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              _NewTopicButton(
                                  roadmapId: widget.roadmap.id,
                                  orderIndex: _topics.length,
                                  onAdded: _loadData),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.roadmap.title,
                            style: const TextStyle(
                                fontSize: 26,
                                height: 1.05,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.8),
                          ),
                          if (widget.roadmap.description?.isNotEmpty ??
                              false) ...[
                            const SizedBox(height: 8),
                            Text(widget.roadmap.description!,
                                style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: AppColors.textSecondary)),
                          ],
                          const SizedBox(height: 12),
                          _RoadmapProgress(topics: _topics, tasks: _tasks),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _topics.isEmpty
                        ? _EmptyRoadmap(
                            onAddTopic: () => _NewTopicButton(
                              roadmapId: widget.roadmap.id,
                              orderIndex: 0,
                              onAdded: _loadData,
                            ).showCreateDialog(context),
                          )
                        : Stack(
                            key: _pathKey,
                            children: [
                              if (_cardBounds.length == _topics.length)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: AnimatedBuilder(
                                      animation: _routeAnimation,
                                      builder: (context, _) => CustomPaint(
                                        painter: RoadmapSpinePainter(
                                          cardBounds: _cardBounds,
                                          topics: _topics,
                                          accentColor: AppColors.action,
                                          progress: Curves.easeOutCubic
                                              .transform(_routeAnimation.value),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: NotificationListener<
                                    SizeChangedLayoutNotification>(
                                  onNotification: (_) {
                                    _scheduleGeometryUpdate();
                                    return false;
                                  },
                                  child: Column(
                                    children: [
                                      for (int i = 0; i < _topics.length; i++)
                                        SizeChangedLayoutNotifier(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 64),
                                            child: TopicCard(
                                              cardKey: _cardKeys[i],
                                              topic: _topics[i],
                                              roadmap: widget.roadmap,
                                              index: i,
                                              onTasksChanged:
                                                  _reloadRoadmapTasks,
                                              onGeometryChanged:
                                                  _scheduleGeometryUpdate,
                                              onStatusChanged:
                                                  (newStatus) async {
                                                final updated = _topics[i]
                                                    .copyWith(
                                                        status: newStatus);
                                                await context
                                                    .read<RoadmapController>()
                                                    .updateTopic(updated);
                                                _loadData();
                                              },
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  SliverToBoxAdapter(
                    child: TaskTimeView(
                        roadmapId: widget.roadmap.id, topics: _topics),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 60)),
                ],
              ),
      ),
    );
  }
}

class _NewTopicButton extends StatelessWidget {
  const _NewTopicButton(
      {required this.roadmapId,
      required this.orderIndex,
      required this.onAdded});
  final String roadmapId;
  final int orderIndex;
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showCreateDialog(context),
      tooltip: 'Add Topic',
      icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void showCreateDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Topic',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Topic Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isNotEmpty) {
                await context.read<RoadmapController>().createTopic(
                    roadmapId: roadmapId, title: title, orderIndex: orderIndex);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                onAdded();
              }
            },
            child: const Text('Add',
                style: TextStyle(
                    color: AppColors.action, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _RoadmapProgress extends StatelessWidget {
  const _RoadmapProgress({required this.topics, required this.tasks});

  final List<Topic> topics;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((t) => t.isCompleted).length;
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;
    final pct = (progress * 100).round();
    final completedTopics = topics.where((t) => t.status == TopicStatus.completed).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.action.withValues(alpha: 0.08),
            AppColors.attention.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.action.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'complete',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '$completedTopics / ${topics.length} topics',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.attention),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completed of ${tasks.length} tasks completed',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EmptyRoadmap extends StatelessWidget {
  const _EmptyRoadmap({required this.onAddTopic});

  final VoidCallback onAddTopic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 28, 40, 40),
      child: Column(
        children: [
          const Text('No Topics yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Break this Roadmap into a few major stages.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onAddTopic,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Topic'),
          ),
        ],
      ),
    );
  }
}

Uint8List _xlsxBytes(List<List<String>> rows) {
  final sheetRows = [
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
      '<row r="${rowIndex + 1}">${[
        for (var columnIndex = 0;
            columnIndex < rows[rowIndex].length;
            columnIndex++)
          '<c r="${_excelColumn(columnIndex)}${rowIndex + 1}" t="inlineStr"><is><t xml:space="preserve">${_xmlEscape(rows[rowIndex][columnIndex])}</t></is></c>',
      ].join()}</row>',
  ].join();
  final files = <String, String>{
    '[Content_Types].xml':
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>''',
    '_rels/.rels':
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>''',
    'xl/workbook.xml':
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Roadmap" sheetId="1" r:id="rId1"/></sheets></workbook>''',
    'xl/_rels/workbook.xml.rels':
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>''',
    'xl/worksheets/sheet1.xml':
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>$sheetRows</sheetData></worksheet>''',
  };
  final archive = Archive();
  for (final entry in files.entries) {
    final content = utf8.encode(entry.value);
    archive.addFile(ArchiveFile(entry.key, content.length, content));
  }
  final workbook = ZipEncoder().encode(archive);
  return Uint8List.fromList(workbook);
}

String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';

String _xmlEscape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

String _excelColumn(int index) {
  var value = index + 1;
  var column = '';
  while (value > 0) {
    value--;
    column = String.fromCharCode(65 + value % 26) + column;
    value ~/= 26;
  }
  return column;
}

