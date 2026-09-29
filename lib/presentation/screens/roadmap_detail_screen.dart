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

// Inline palette resolver — kept in sync with roadmap_list_screen palette.
const _kDetailPalette = [
  Color(0xFF1E3A8A), Color(0xFF0EA5E9), Color(0xFF0D9488), Color(0xFF059669),
  Color(0xFFF59E0B), Color(0xFFFB7185), Color(0xFFF472B6), Color(0xFF7C3AED),
  Color(0xFF4F46E5), Color(0xFFEF4444), Color(0xFF475569), Color(0xFFF59E0B),
];

Color _roadmapAccent(Roadmap r) {
  final idx = r.colorIndex >= 0
      ? r.colorIndex % _kDetailPalette.length
      : r.id.hashCode.abs() % _kDetailPalette.length;
  return _kDetailPalette[idx];
}

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
    final accent = _roadmapAccent(widget.roadmap);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.action))
          : CustomScrollView(
              slivers: [
                // ── Gradient header band ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(28)),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Toolbar row
                            Row(
                              children: [
                                // Pill back button
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    height: 34,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.arrow_back_rounded,
                                            size: 16, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text('Back',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Import
                                _HeaderAction(
                                  icon: Icons.upload_file_rounded,
                                  label: 'Import',
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RoadmapImportScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Export
                                PopupMenuButton<bool>(
                                  tooltip: 'Export Roadmap',
                                  color: AppColors.surface,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  padding: EdgeInsets.zero,
                                  onSelected: _exportRoadmap,
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                        value: false,
                                        child: Text('Export CSV')),
                                    PopupMenuItem(
                                        value: true,
                                        child: Text('Export Excel')),
                                  ],
                                  child: Container(
                                    height: 34,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.ios_share_rounded,
                                            size: 15, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text('Export',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Add Topic
                                _NewTopicButton(
                                  roadmapId: widget.roadmap.id,
                                  orderIndex: _topics.length,
                                  onAdded: _loadData,
                                  accent: accent,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Roadmap title
                            Text(
                              widget.roadmap.title,
                              style: const TextStyle(
                                  fontSize: 26,
                                  height: 1.05,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.8),
                            ),
                            if (widget.roadmap.description?.isNotEmpty ??
                                false) ...[
                              const SizedBox(height: 6),
                              Text(widget.roadmap.description!,
                                  style: TextStyle(
                                      fontSize: 14,
                                      height: 1.45,
                                      color:
                                          Colors.white.withValues(alpha: 0.8))),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // ── Progress card ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _RoadmapProgress(
                        topics: _topics, tasks: _tasks, accent: accent),
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
    );
  }
}

class _NewTopicButton extends StatelessWidget {
  const _NewTopicButton({
    required this.roadmapId,
    required this.orderIndex,
    required this.onAdded,
    this.accent = const Color(0xFF0EA5E9),
  });
  final String roadmapId;
  final int orderIndex;
  final VoidCallback onAdded;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showCreateDialog(context),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add_rounded, size: 16, color: Colors.white),
            SizedBox(width: 5),
            Text('Topic',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void showCreateDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent top strip
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: accent,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.route_rounded,
                            size: 18, color: accent),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add Topic',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3)),
                            Text('A stage in this roadmap',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Topic name',
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: accent, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  color: AppColors.textSecondary))),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final title = titleCtrl.text.trim();
                          if (title.isEmpty) return;
                          await context
                              .read<RoadmapController>()
                              .createTopic(
                                  roadmapId: roadmapId,
                                  title: title,
                                  orderIndex: orderIndex);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          onAdded();
                        },
                        style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pill action button used in the gradient header toolbar.
class _HeaderAction extends StatelessWidget {
  const _HeaderAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ],
          ),
        ),
      );
}

class _RoadmapProgress extends StatelessWidget {
  const _RoadmapProgress(
      {required this.topics, required this.tasks, required this.accent});

  final List<Topic> topics;
  final List<Task> tasks;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((t) => t.isCompleted).length;
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;
    final pct = (progress * 100).round();
    final completedTopics =
        topics.where((t) => t.status == TopicStatus.completed).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
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
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: accent,
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
          // Animated progress bar
          TweenAnimationBuilder<double>(
            key: ValueKey(progress),
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completed of ${tasks.length} tasks completed',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
