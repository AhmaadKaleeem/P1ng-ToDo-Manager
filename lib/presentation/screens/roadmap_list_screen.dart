import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'package:todow/domain/models/roadmap.dart';
import 'package:todow/presentation/controllers/roadmap_controller.dart';
import 'package:todow/presentation/screens/roadmap_detail_screen.dart';
import 'package:todow/presentation/screens/roadmap_import_screen.dart';

const _accentColors = [
  AppColors.decorNavy,
  AppColors.decorPink,
  AppColors.decorCoral,
  AppColors.action,
  AppColors.attention,
];

const _gradients = [
  LinearGradient(
    colors: [AppColors.decorNavy, Color(0xFF3155A2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  LinearGradient(
    colors: [AppColors.decorPink, AppColors.decorCoral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  LinearGradient(
    colors: [AppColors.attention, AppColors.decorCoral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  LinearGradient(
    colors: [AppColors.action, Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFB7185)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
];

LinearGradient _gradient(int index) =>
    _gradients[index % _gradients.length];
Color _accent(int index) => _accentColors[index % _accentColors.length];

class RoadmapListScreen extends StatelessWidget {
  const RoadmapListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Roadmaps',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.8,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your long-term learning paths',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _ImportButton(),
                  const SizedBox(width: 8),
                  _NewRoadmapButton(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<RoadmapController>(
                builder: (context, ctrl, _) {
                  if (ctrl.loading) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.action, strokeWidth: 2));
                  }
                  if (ctrl.roadmaps.isEmpty) {
                    return _EmptyState(
                      onCreate: () =>
                          _NewRoadmapButton().showCreateDialog(context),
                      onImport: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RoadmapImportScreen())),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    itemCount: ctrl.roadmaps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final roadmap = ctrl.roadmaps[i];
                      return _RoadmapCard(
                        roadmap: roadmap,
                        isLead: i == 0,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  RoadmapDetailScreen(roadmap: roadmap)),
                        ),
                        onDelete: () => context
                            .read<RoadmapController>()
                            .deleteRoadmap(roadmap.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RoadmapImportScreen())),
        icon: const Icon(Icons.upload_file_rounded, size: 18),
        label: const Text('Import'),
        style:
            TextButton.styleFrom(foregroundColor: AppColors.action, minimumSize: const Size(48, 48)),
      );
}

class _NewRoadmapButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: () => showCreateDialog(context),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.action,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('New',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );

  void showCreateDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int selectedColor = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => _CreateRoadmapSheet(
          titleCtrl: titleCtrl,
          descCtrl: descCtrl,
          selectedColor: selectedColor,
          onColorSelected: (i) => setState(() => selectedColor = i),
          onSave: () {
            final title = titleCtrl.text.trim();
            if (title.isEmpty) return;
            context.read<RoadmapController>().createRoadmap(
                title: title,
                description: descCtrl.text.trim().isEmpty
                    ? null
                    : descCtrl.text.trim(),
                colorIndex: selectedColor);
            Navigator.pop(ctx);
          },
          onImport: () {
            Navigator.pop(ctx);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RoadmapImportScreen()));
          },
        ),
      ),
    );
  }
}

class _RoadmapCard extends StatefulWidget {
  const _RoadmapCard({
    required this.roadmap,
    required this.isLead,
    required this.onTap,
    required this.onDelete,
  });

  final Roadmap roadmap;
  final bool isLead;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_RoadmapCard> createState() => _RoadmapCardState();
}

class _RoadmapCardState extends State<_RoadmapCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(widget.roadmap.colorIndex);
    final grad = _gradient(widget.roadmap.colorIndex);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      onLongPress: () => _confirmDelete(context),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutExpo,
        child: Container(
          constraints: BoxConstraints(minHeight: widget.isLead ? 210 : 190),
          decoration: BoxDecoration(
            gradient: grad,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative arc in top-right
              Positioned(
                right: -24,
                top: -24,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: -36,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.route_rounded,
                                  size: 11, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                'ROADMAP',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded,
                              size: 17, color: Colors.white),
                        ),
                      ],
                    ),
                    SizedBox(height: widget.isLead ? 40 : 28),
                    Text(
                      widget.roadmap.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.6,
                      ),
                    ),
                    if (widget.roadmap.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.roadmap.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0, // roadmap list doesn't have progress data, placeholder
                        minHeight: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Roadmap?',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: const Text('This also deletes all Topics. Tasks are kept.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete();
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.alert, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate, required this.onImport});

  final VoidCallback onCreate;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.divider.withValues(alpha: 0.4),
                  shape: BoxShape.circle),
              child: const Icon(Icons.route_outlined,
                  size: 32, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            const Text('No roadmaps yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
                'Create a roadmap to plan your learning journey in structured stages.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create manually'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.action,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Import CSV or Excel'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: AppColors.divider)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateRoadmapSheet extends StatelessWidget {
  const _CreateRoadmapSheet({
    required this.titleCtrl,
    required this.descCtrl,
    required this.selectedColor,
    required this.onColorSelected,
    required this.onSave,
    required this.onImport,
  });

  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final int selectedColor;
  final ValueChanged<int> onColorSelected;
  final VoidCallback onSave;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 24),
          const Text('New Roadmap',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5)),
          const SizedBox(height: 20),
          _SheetField(
              controller: titleCtrl, hint: 'Title', autofocus: true),
          const SizedBox(height: 12),
          _SheetField(
              controller: descCtrl, hint: 'Description (optional)'),
          const SizedBox(height: 20),
          const Text('Accent',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
                _accentColors.length,
                (i) => GestureDetector(
                      onTap: () => onColorSelected(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 10),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _accentColors[i],
                          shape: BoxShape.circle,
                          border: selectedColor == i
                              ? Border.all(
                                  color: AppColors.textPrimary, width: 2.5)
                              : null,
                        ),
                      ),
                    )),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.action,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Create Roadmap',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Import CSV or Excel instead'),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.action,
                minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField(
      {required this.controller,
      required this.hint,
      this.autofocus = false});

  final TextEditingController controller;
  final String hint;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.action)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
