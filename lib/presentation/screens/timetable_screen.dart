import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'package:todow/core/utils/date_format.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/timetable_entry.dart';
import 'package:todow/presentation/controllers/timetable_controller.dart';
import 'package:todow/presentation/widgets/timetable_editor.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late Weekday _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = WeekdayExt.fromDartWeekday(DateTime.now().weekday);
  }

  Future<void> _delete(
      TimetableController controller, TimetableEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this class?'),
        content: Text(
            '${entry.courseName} will be removed from ${entry.weekday.fullLabel} every week.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep class')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) await controller.delete(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TimetableController>();
    final entries = controller.forDay(_selectedDay);
    final today = WeekdayExt.fromDartWeekday(DateTime.now().weekday);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Timetable'),
        actions: [
          IconButton(
            onPressed: () =>
                showTimetableEditor(context, initialWeekday: _selectedDay),
            icon: const Icon(Icons.add),
            tooltip: 'Add class',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text(
            'Your weekly classes',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Repeats each week. Change a day or time whenever your schedule shifts.',
            style: TextStyle(
                fontSize: 14, height: 1.4, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: Weekday.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = Weekday.values[index];
                final selected = day == _selectedDay;
                return ChoiceChip(
                  label: Text(day.fullLabel.substring(0, 3)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedDay = day),
                  selectedColor: AppColors.action,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                      color: selected ? AppColors.action : AppColors.divider),
                  shape: const StadiumBorder(),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            _EmptyDay(
              isToday: _selectedDay == today,
              onAdd: () =>
                  showTimetableEditor(context, initialWeekday: _selectedDay),
            )
          else
            ...entries.map((entry) => _ClassCard(
                  entry: entry,
                  onEdit: () => showTimetableEditor(context, entry: entry),
                  onDelete: () => _delete(controller, entry),
                )),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard(
      {required this.entry, required this.onEdit, required this.onDelete});

  final TimetableEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 44,
                    decoration: BoxDecoration(
                        color: AppColors.action,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.courseName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(
                          '${AppDateFormat.time(entry.startTime)} – ${AppDateFormat.time(entry.endTime)}${entry.room?.trim().isNotEmpty == true ? ' · ${entry.room}' : ''}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit class'),
                  IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.alert),
                      tooltip: 'Delete class'),
                ],
              ),
            ),
          ),
        ),
      );
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
        child: Row(
          children: [
            Expanded(
              child: Text(
                isToday ? 'No classes today' : 'No classes scheduled',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
            ),
            TextButton(onPressed: onAdd, child: const Text('Add class')),
          ],
        ),
      );
}
