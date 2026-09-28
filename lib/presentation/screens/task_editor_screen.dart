import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/presentation/controllers/task_controller.dart';
import 'package:todow/presentation/widgets/corner_arc_decor.dart';
import 'package:todow/presentation/widgets/attachments_section.dart';

const _kRoadmaps = ['Master Roadmap', 'Daily Tasks', 'Personal Notes'];

class TaskEditorScreen extends StatefulWidget {
  final Task? task;
  const TaskEditorScreen({super.key, this.task});
  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late TaskPriority _priority;
  DateTime? _dueAt;
  late final List<String> _roadmaps;
  late String _selectedRoadmap;
  Task? _workingTask;

  @override
  void initState() {
    super.initState();
    _workingTask = widget.task;
    _title    = TextEditingController(text: _workingTask?.title ?? '');
    _notes    = TextEditingController(text: _workingTask?.description ?? '');
    _priority = _workingTask?.priority ?? TaskPriority.none;
    _dueAt    = _workingTask?.dueAt;
    _roadmaps = List.of(_kRoadmaps);
    final initialCategory = _workingTask?.category ?? _kRoadmaps.first;
    if (!_roadmaps.contains(initialCategory)) {
      _roadmaps.add(initialCategory);
    }
    _selectedRoadmap = initialCategory;
  }

  Future<void> _addNewRoadmap() async {
    final ctrl = TextEditingController();
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surface,
        title: const Text('New Project', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Project name',
            hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.action)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.action, foregroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      setState(() {
        if (!_roadmaps.contains(newName)) {
          _roadmaps.add(newName);
        }
        _selectedRoadmap = newName;
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _setQuickDate(int daysFromNow) =>
      setState(() => _dueAt = DateTime.now().add(Duration(days: daysFromNow)));

  bool _isQuickDate(int daysFromNow) {
    if (_dueAt == null) return false;
    final target = DateTime.now().add(Duration(days: daysFromNow));
    return _dueAt!.year == target.year && _dueAt!.month == target.month && _dueAt!.day == target.day;
  }

  bool get _isCustomDate => _dueAt != null && !_isQuickDate(0) && !_isQuickDate(1);

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.action,
            onPrimary: AppColors.surface,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _dueAt = d);
  }

  Future<Task> _autoSave() async {
    if (_workingTask != null) return _workingTask!;
    final tc = context.read<TaskController>();
    final title = _title.text.trim().isEmpty ? 'Untitled' : _title.text.trim();
    final task = await tc.createTask(title: title, description: _notes.text.trim(), priority: _priority, dueAt: _dueAt, category: _selectedRoadmap);
    setState(() {
      _workingTask = task;
      if (_title.text.trim().isEmpty) _title.text = 'Untitled';
    });
    return task;
  }

  bool _canPop = false;

  void _save() {
    if (_title.text.trim().isNotEmpty) {
      final tc = context.read<TaskController>();
      if (_workingTask == null) {
        tc.createTask(title: _title.text.trim(), description: _notes.text.trim(), priority: _priority, dueAt: _dueAt, category: _selectedRoadmap);
      } else {
        tc.updateTask(_workingTask!.copyWith(
          title: _title.text.trim(), 
          description: _notes.text.trim(), 
          priority: _priority, 
          dueAt: _dueAt, 
          clearDueAt: _dueAt == null,
          category: _selectedRoadmap,
        ));
      }
    }
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  String _fmtCustomDate(DateTime d) {
    const days   = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  Color _getProjectColor(int index) {
    const colors = [AppColors.decorNavy, AppColors.decorPink, AppColors.decorCoral];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isNew = _workingTask == null;

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _save();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const CornerArcDecor(corner: Alignment.topLeft),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Close ─────────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _save,
                          child: Container(
                            width: 36, height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.divider, width: 1),
                          ),
                          child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Hero title + 40dp amber underline ─────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isNew ? 'New task' : 'Edit task',
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.0, letterSpacing: -0.8, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 40, height: 2,
                        decoration: BoxDecoration(color: AppColors.attention, borderRadius: BorderRadius.circular(1)),
                      ),
                    ],
                  ),
                ),

                // ── Form body ─────────────────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    children: [

                      // ── WHEN ────────────────────────────────────────────────
                      const _SectionLabel('WHEN'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _WhenPill(label: 'Today',    selected: _isQuickDate(0), onTap: () => _setQuickDate(0)),
                          const SizedBox(width: 8),
                          _WhenPill(label: 'Tomorrow', selected: _isQuickDate(1), onTap: () => _setQuickDate(1)),
                          const SizedBox(width: 8),
                          _IconBtn(icon: Icons.schedule_rounded,           onTap: _pickDate, active: _isCustomDate),
                          const SizedBox(width: 8),
                          _IconBtn(
                            icon: Icons.notifications_none_rounded,
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text('Reminders coming soon'),
                              backgroundColor: AppColors.textPrimary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            )),
                          ),
                        ],
                      ),
                      if (_isCustomDate) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Scheduled for ${_fmtCustomDate(_dueAt!)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ── PROJECTS ────────────────────────────────────────────
                      const _SectionLabel('PROJECTS'),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Row(
                            children: [
                              _ProjectPill(label: '+ New', selected: false, outlined: true, activeColor: AppColors.action, onTap: _addNewRoadmap),
                              const SizedBox(width: 8),
                              for (int i = 0; i < _roadmaps.length; i++) ...[
                                _ProjectPill(
                                  label: _roadmaps[i],
                                  selected: _selectedRoadmap == _roadmaps[i],
                                  outlined: false,
                                  activeColor: _getProjectColor(i),
                                  onTap: () => setState(() => _selectedRoadmap = _roadmaps[i]),
                                ),
                                if (i < _roadmaps.length - 1) const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── PRIORITY ────────────────────────────────────────────
                      const _SectionLabel('PRIORITY'),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: TaskPriority.values.map((p) {
                            final sel = _priority == p;
                            return Padding(
                              padding: EdgeInsets.only(right: p != TaskPriority.values.last ? 8 : 0),
                              child: GestureDetector(
                                onTap: () => setState(() => _priority = p),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: sel ? AppColors.action : Colors.transparent,
                                    border: sel ? null : Border.all(color: AppColors.divider, width: 1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(p.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: sel ? AppColors.surface : AppColors.textSecondary)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── TASK ────────────────────────────────────────────────
                      const _SectionLabel('TASK'),
                      const SizedBox(height: 12),
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.surface, 
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5), width: 1),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 8)),
                          ],
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _title, 
                              onChanged: (_) => setState(() {}), 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.4), 
                              decoration: InputDecoration(
                                hintText: 'What needs to be done?',
                                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 18, fontWeight: FontWeight.w500),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                              ),
                            ),
                            Container(height: 1, color: AppColors.divider.withValues(alpha: 0.3)),
                            TextField(
                              controller: _notes, 
                              onChanged: (_) => setState(() {}), 
                              maxLines: null, 
                              minLines: 4, 
                              style: const TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w400, color: AppColors.textPrimary), 
                              decoration: InputDecoration(
                                hintText: 'Add extra details, context, or links...',
                                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 15, fontWeight: FontWeight.w400),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                      
                      AttachmentsSection(task: _workingTask, onAutoSave: _autoSave),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),

                // ── CTA ───────────────────────────────────────────────────────
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.action,
                        foregroundColor: AppColors.surface,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(isNew ? 'Create task' : 'Save changes', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
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

// ── Components ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
  );
}

class _WhenPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _WhenPill({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: selected ? AppColors.action : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: selected ? null : Border.all(color: AppColors.divider, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(fontSize: 15, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? AppColors.surface : AppColors.textSecondary),
      ),
    ),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _IconBtn({required this.icon, required this.onTap, this.active = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: active ? AppColors.action : AppColors.surface,
        shape: BoxShape.circle,
        border: active ? null : Border.all(color: AppColors.divider, width: 1),
      ),
      child: Icon(icon, size: 18, color: active ? AppColors.surface : AppColors.textSecondary),
    ),
  );
}

class _ProjectPill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool outlined;
  final Color activeColor;
  final VoidCallback onTap;
  const _ProjectPill({required this.label, required this.selected, required this.outlined, required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: selected ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: !selected ? Border.all(color: AppColors.divider, width: 1) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppColors.surface : AppColors.textSecondary,
        ),
      ),
    ),
  );
}
