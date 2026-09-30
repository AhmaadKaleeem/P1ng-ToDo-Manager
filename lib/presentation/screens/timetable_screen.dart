import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'package:todow/core/utils/date_format.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/timetable_entry.dart';
import 'package:todow/presentation/controllers/timetable_controller.dart';
import 'package:todow/presentation/controllers/task_controller.dart';
import 'package:todow/presentation/screens/app_shell.dart';
import 'package:todow/presentation/screens/timetable_import_screen.dart';
import 'package:todow/presentation/widgets/timetable_editor.dart';

enum _TimetableView { week, day }

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late Weekday _selectedDay;
  late DateTime _selectedDate;
  TimetableKind _selectedKind = TimetableKind.university;
  _TimetableView _view = _TimetableView.day;

  @override
  void initState() {
    super.initState();
    _selectedDay = WeekdayExt.fromDartWeekday(DateTime.now().weekday);
    _selectedDate = DateTime.now();
  }

  Future<void> _delete(
      TimetableController controller, TimetableEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.scheduleKind == TimetableKind.personal
            ? 'Delete this activity?'
            : 'Delete this class?'),
        content: Text(
            '${entry.courseName} will be removed from ${entry.weekday.fullLabel} in your ${_scheduleName(entry.scheduleKind).toLowerCase()} timetable.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(entry.scheduleKind == TimetableKind.personal
                  ? 'Keep activity'
                  : 'Keep class')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) await controller.delete(entry.id);
  }

  void _openImport() => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TimetableImportScreen(scheduleKind: _selectedKind),
      ));

  Future<void> _edit(TimetableEntry entry) =>
      showTimetableEditor(context, entry: entry);

  Future<void> _createTaskFromEntry(TimetableEntry entry) async {
    if (entry.taskId != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This timetable item is already linked to a task.')));
      return;
    }
    final date = entry.scheduledDate ?? DateTime.now();
    final dueAt = DateTime(date.year, date.month, date.day, entry.endTime.hour,
        entry.endTime.minute);
    final task = await context.read<TaskController>().createTask(
          title: entry.courseName,
          description: entry.instructor,
          dueAt: dueAt,
          category: entry.category ?? 'Personal timetable',
        );
    if (!mounted) return;
    await context.read<TimetableController>().update(TimetableEntry(
          id: entry.id,
          courseName: entry.courseName,
          instructor: entry.instructor,
          weekday: entry.weekday,
          startTime: entry.startTime,
          endTime: entry.endTime,
          scheduleKind: entry.scheduleKind,
          room: entry.room,
          colorValue: entry.colorValue,
          category: entry.category,
          scheduledDate: entry.scheduledDate,
          repeatWeekly: entry.repeatWeekly,
          taskId: task.id,
        ));
  }

  int? _primaryIndex(List<TimetableEntry> entries, Weekday day) {
    final now = DateTime.now();
    if (day != WeekdayExt.fromDartWeekday(now.weekday) ||
        _selectedDate.year != now.year ||
        _selectedDate.month != now.month ||
        _selectedDate.day != now.day) {
      return null;
    }
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final start = DateTime(now.year, now.month, now.day, entry.startTime.hour,
          entry.startTime.minute);
      final end = DateTime(now.year, now.month, now.day, entry.endTime.hour,
          entry.endTime.minute);
      if (!now.isBefore(start) && now.isBefore(end)) return i;
      if (start.isAfter(now)) return i;
    }
    return null;
  }

  void _shiftDay(int amount) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: amount));
      _selectedDay = WeekdayExt.fromDartWeekday(_selectedDate.weekday);
    });
  }

  Future<void> _copyUniversityEntries(TimetableController controller) async {
    final source = controller.entriesFor(TimetableKind.university);
    if (source.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add university classes before copying them.')));
      return;
    }
    final personal = controller.entriesFor(TimetableKind.personal);
    var copied = 0;
    for (final entry in source) {
      if (personal.any((item) =>
          item.courseName == entry.courseName &&
          item.weekday == entry.weekday &&
          item.startTime.hour == entry.startTime.hour &&
          item.startTime.minute == entry.startTime.minute)) {
        continue;
      }
      await controller.add(
          courseName: entry.courseName,
          instructor: entry.instructor,
          weekday: entry.weekday,
          startTime: entry.startTime,
          endTime: entry.endTime,
          scheduleKind: TimetableKind.personal,
          room: entry.room);
      copied++;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(copied == 0
              ? 'Your university classes are already in Personal.'
              : '$copied independent ${copied == 1 ? 'class' : 'classes'} copied to Personal.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TimetableController>();
    final today = WeekdayExt.fromDartWeekday(DateTime.now().weekday);
    final entries = controller
        .forDay(
          _selectedDay,
          scheduleKind: _selectedKind,
        )
        .where((entry) =>
            entry.repeatWeekly ||
            (entry.scheduledDate!.year == _selectedDate.year &&
                entry.scheduledDate!.month == _selectedDate.month &&
                entry.scheduledDate!.day == _selectedDate.day))
        .toList();
    final primaryIndex = _primaryIndex(entries, _selectedDay);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
            tooltip: 'Back to Home',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => AppShellScope.of(context).selectPage(0)),
        title: const Text('Timetable'),
        actions: [
          IconButton(
              onPressed: _openImport,
              icon: const Icon(Icons.file_upload_outlined),
              tooltip: 'Import timetable'),
          IconButton(
              onPressed: () => showTimetableEditor(
                    context,
                    initialWeekday: _selectedDay,
                    initialDate: _selectedDate,
                    scheduleKind: _selectedKind,
                  ),
              icon: const Icon(Icons.add),
              tooltip: _selectedKind == TimetableKind.personal
                  ? 'Add activity'
                  : 'Add class'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text(
            'Your schedule, your way',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedKind == TimetableKind.university
                ? 'University classes repeat weekly. Adjust individual days as needed.'
                : 'Plan activities, one-off events, and time for linked tasks.',
            style: TextStyle(
                fontSize: 14, height: 1.4, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
                child: _ScheduleChoice(
                    label: 'University',
                    selected: _selectedKind == TimetableKind.university,
                    onTap: () => setState(
                        () => _selectedKind = TimetableKind.university))),
            const SizedBox(width: 10),
            Expanded(
                child: _ScheduleChoice(
                    label: 'Personal',
                    selected: _selectedKind == TimetableKind.personal,
                    onTap: () => setState(
                        () => _selectedKind = TimetableKind.personal))),
          ]),
          if (_selectedKind == TimetableKind.personal)
            Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                    onPressed: () => _copyUniversityEntries(controller),
                    icon: const Icon(Icons.copy_all_outlined, size: 18),
                    label: const Text('Copy university classes here'))),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: SegmentedButton<_TimetableView>(
                segments: const [
                  ButtonSegment(
                      value: _TimetableView.week, label: Text('Week')),
                  ButtonSegment(value: _TimetableView.day, label: Text('Day')),
                ],
                selected: {_view},
                onSelectionChanged: (selected) =>
                    setState(() => _view = selected.first),
                showSelectedIcon: false,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected)
                          ? AppColors.action
                          : AppColors.surface),
                  foregroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected)
                          ? Colors.white
                          : AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _selectedDay = today;
                _selectedDate = DateTime.now();
                _view = _TimetableView.day;
              }),
              icon: const Icon(Icons.today_outlined, size: 17),
              label: const Text('Today'),
            ),
          ]),
          const SizedBox(height: 14),
          if (_view == _TimetableView.day) ...[
            Row(children: [
              IconButton(
                  onPressed: () => _shiftDay(-1),
                  tooltip: 'Previous day',
                  icon: const Icon(Icons.chevron_left)),
              Expanded(
                  child: Center(
                      child: Text(
                          _selectedKind == TimetableKind.personal
                              ? '${_selectedDay.fullLabel} · ${_selectedDate.month}/${_selectedDate.day}'
                              : _selectedDay.fullLabel,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)))),
              IconButton(
                  onPressed: () => _shiftDay(1),
                  tooltip: 'Next day',
                  icon: const Icon(Icons.chevron_right)),
            ]),
            if (entries.isEmpty)
              _EmptyDay(
                isToday: _selectedDay == today,
                onAdd: () => showTimetableEditor(
                  context,
                  initialWeekday: _selectedDay,
                  initialDate: _selectedDate,
                  scheduleKind: _selectedKind,
                ),
              )
            else
              ...entries.indexed.map((item) => _ClassCard(
                    entry: item.$2,
                    emphasis:
                        item.$1 == primaryIndex ? _currentState(item.$2) : null,
                    onEdit: () => _edit(item.$2),
                    onDelete: () => _delete(controller, item.$2),
                    onCreateTask: () => _createTaskFromEntry(item.$2),
                  )),
          ] else ...[
            for (final day in Weekday.values)
              _WeekdaySection(
                day: day,
                entries: _entriesForWeekday(controller, day),
                primaryIndex:
                    _primaryIndex(_entriesForWeekday(controller, day), day),
                onOpenDay: () => setState(() {
                  _selectedDay = day;
                  final offset = day.index - _selectedDay.index;
                  _selectedDate = _selectedDate.add(Duration(days: offset));
                  _selectedDay = day;
                  _view = _TimetableView.day;
                }),
              ),
          ],
        ],
      ),
    );
  }

  String? _currentState(TimetableEntry entry) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, entry.startTime.hour,
        entry.startTime.minute);
    final end = DateTime(
        now.year, now.month, now.day, entry.endTime.hour, entry.endTime.minute);
    return !now.isBefore(start) && now.isBefore(end) ? 'NOW' : 'NEXT';
  }

  List<TimetableEntry> _entriesForWeekday(
      TimetableController controller, Weekday day) {
    final weekStart =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
            .subtract(Duration(days: _selectedDate.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return controller.forDay(day, scheduleKind: _selectedKind).where((entry) {
      final date = entry.scheduledDate;
      return entry.repeatWeekly ||
          (date != null && !date.isBefore(weekStart) && date.isBefore(weekEnd));
    }).toList();
  }
}

String _scheduleName(TimetableKind kind) =>
    kind == TimetableKind.university ? 'University' : 'Personal';

Color _entryColor(TimetableEntry entry) {
  switch (entry.category?.toLowerCase()) {
    case 'study':
      return AppColors.decorNavy;
    case 'appointment':
      return AppColors.decorPink;
    case 'work':
      return AppColors.attention;
    case 'task':
    case 'roadmap':
      return AppColors.decorCoral;
    default:
      return entry.scheduleKind == TimetableKind.personal
          ? AppColors.decorPink
          : AppColors.action;
  }
}

class _ScheduleChoice extends StatelessWidget {
  const _ScheduleChoice(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: label == 'Personal'
                      ? [AppColors.decorPink, AppColors.decorCoral]
                      : [AppColors.action, const Color(0xFF0284C7)])
              : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: selected ? Colors.transparent : AppColors.divider),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textPrimary))),
        ),
      );
}

class _WeekdaySection extends StatelessWidget {
  const _WeekdaySection({
    required this.day,
    required this.entries,
    required this.primaryIndex,
    required this.onOpenDay,
  });

  final Weekday day;
  final List<TimetableEntry> entries;
  final int? primaryIndex;
  final VoidCallback onOpenDay;

  @override
  Widget build(BuildContext context) {
    final isToday = day == WeekdayExt.fromDartWeekday(DateTime.now().weekday);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpenDay,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(day.fullLabel,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isToday
                                ? AppColors.action
                                : AppColors.textPrimary))),
                Text(
                    '${entries.length} ${entries.length == 1 ? 'class' : 'classes'}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textSecondary),
              ]),
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 9),
                for (var i = 0; i < entries.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(children: [
                      SizedBox(
                          width: 68,
                          child: Text(AppDateFormat.time(entries[i].startTime),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: i == primaryIndex
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: i == primaryIndex
                                      ? AppColors.action
                                      : AppColors.textSecondary))),
                      Expanded(
                          child: Text(entries[i].courseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textPrimary))),
                      if (i == primaryIndex)
                        Text(
                          _isCurrent(entries[i]) ? 'NOW' : 'NEXT',
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: AppColors.action),
                        ),
                    ]),
                  ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('No classes',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  bool _isCurrent(TimetableEntry entry) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, entry.startTime.hour,
        entry.startTime.minute);
    final end = DateTime(
        now.year, now.month, now.day, entry.endTime.hour, entry.endTime.minute);
    return !now.isBefore(start) && now.isBefore(end);
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard(
      {required this.entry,
      required this.emphasis,
      required this.onEdit,
      required this.onDelete,
      required this.onCreateTask});

  final TimetableEntry entry;
  final String? emphasis;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    final accent = _entryColor(entry);
    final details = [
      if (entry.instructor.trim().isNotEmpty) entry.instructor,
      if (entry.room?.trim().isNotEmpty == true) entry.room!,
      if (entry.category?.isNotEmpty == true) entry.category!,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Color.alphaBlend(
            accent.withValues(alpha: 0.055), AppColors.surface),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
            child: Row(children: [
              Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                      color: emphasis == null ? accent : AppColors.action,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 12),
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppDateFormat.time(entry.startTime),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(AppDateFormat.time(entry.endTime),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.courseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(
                      details.isEmpty
                          ? entry.scheduleKind == TimetableKind.personal
                              ? 'Personal activity'
                              : 'Course'
                          : details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (emphasis != null)
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Text(emphasis!,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.action)),
                ),
              PopupMenuButton<String>(
                tooltip: 'Class actions',
                onSelected: (action) {
                  if (action == 'edit') onEdit();
                  if (action == 'delete') onDelete();
                  if (action == 'task') onCreateTask();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                      value: 'edit',
                      child: Text(entry.scheduleKind == TimetableKind.personal
                          ? 'Edit activity'
                          : 'Edit class')),
                  if (entry.scheduleKind == TimetableKind.personal)
                    PopupMenuItem(
                        value: 'task',
                        enabled: entry.taskId == null,
                        child: Text(entry.taskId == null
                            ? 'Create task from activity'
                            : 'Linked to task')),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text(entry.scheduleKind == TimetableKind.personal
                          ? 'Delete activity'
                          : 'Delete class')),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.isToday, required this.onAdd});

  final bool isToday;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(
              child: Text(isToday ? 'No classes today' : 'No classes scheduled',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary))),
          TextButton(onPressed: onAdd, child: const Text('Add class')),
        ]),
      );
}
