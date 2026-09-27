import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/presentation/controllers/task_controller.dart';
import 'package:todow/presentation/widgets/corner_arc_decor.dart';
import 'package:todow/presentation/widgets/attachments_section.dart';

const _kRoadmaps = ['Master Roadmap', 'Daily Tasks', 'Business'];

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
  String _selectedRoadmap = _kRoadmaps.first;

  @override
  void initState() {
    super.initState();
    _title    = TextEditingController(text: widget.task?.title ?? '');
    _notes    = TextEditingController(text: widget.task?.description ?? '');
    _priority = widget.task?.priority ?? TaskPriority.none;
    _dueAt    = widget.task?.dueAt;
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
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

  void _save() {
    if (_title.text.trim().isEmpty) { Navigator.pop(context); return; }
    final tc = context.read<TaskController>();
    if (widget.task == null) {
      tc.createTask(title: _title.text.trim(), description: _notes.text.trim(), priority: _priority, dueAt: _dueAt, category: _selectedRoadmap);
    } else {
      tc.updateTask(widget.task!.copyWith(title: _title.text.trim(), description: _notes.text.trim(), priority: _priority, dueAt: _dueAt, category: _selectedRoadmap));
    }
    Navigator.pop(context);
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
    final isNew = widget.task == null;

    return Scaffold(
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
                        onTap: () => Navigator.pop(context),
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
                              _ProjectPill(label: '+ New', selected: false, outlined: true, activeColor: AppColors.action, onTap: () {}),
                              const SizedBox(width: 8),
                              for (int i = 0; i < _kRoadmaps.length; i++) ...[
                                _ProjectPill(
                                  label: _kRoadmaps[i],
                                  selected: _selectedRoadmap == _kRoadmaps[i],
                                  outlined: false,
                                  activeColor: _getProjectColor(i),
                                  onTap: () => setState(() => _selectedRoadmap = _kRoadmaps[i]),
                                ),
                                if (i < _kRoadmaps.length - 1) const SizedBox(width: 8),
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
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            TextField(
                              controller: _title, 
                              onChanged: (_) => setState(() {}), 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary), 
                              decoration: InputDecoration(
                                hintText: 'Task name',
                                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 16, fontWeight: FontWeight.w400),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                              ),
                            ),
                            Container(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
                            TextField(
                              controller: _notes, 
                              onChanged: (_) => setState(() {}), 
                              maxLines: null, 
                              minLines: 3, 
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary), 
                              decoration: InputDecoration(
                                hintText: 'Description (optional)',
                                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.w400),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                      
                      AttachmentsSection(task: widget.task),
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
