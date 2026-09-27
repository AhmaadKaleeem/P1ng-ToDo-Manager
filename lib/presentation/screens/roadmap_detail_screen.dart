import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'package:todow/domain/models/roadmap.dart';
import 'package:todow/presentation/screens/task_editor_screen.dart';

class RoadmapDetailScreen extends StatefulWidget {
  final Roadmap roadmap;

  const RoadmapDetailScreen({super.key, required this.roadmap});

  @override
  State<RoadmapDetailScreen> createState() => _RoadmapDetailScreenState();
}

class _RoadmapDetailScreenState extends State<RoadmapDetailScreen> {
  // Using some mock tasks just for the visual overdrive as requested until the data layer is attached
  final _tasks = [
    _MockRoadmapTask('Create a presentation in Keynote', false),
    _MockRoadmapTask('Give feedback to the team', false),
    _MockRoadmapTask('Book the return tickets', true),
    _MockRoadmapTask('Check some guided tours', true),
  ];

  @override
  Widget build(BuildContext context) {
    final activeTasks = _tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = _tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.background,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: IconButton(
                      icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Hero(
                tag: 'roadmap_${widget.roadmap.id}',
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(32, 64, 32, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(widget.roadmap.title, style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -1.5,
                            )),
                            const SizedBox(height: 12),
                            Text(widget.roadmap.description, style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.4,
                            )),
                            const Spacer(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${widget.roadmap.completedTasks}/${widget.roadmap.totalTasks}', style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                )),
                                const Padding(
                                  padding: EdgeInsets.only(left: 8, bottom: 6),
                                  child: Text('tasks', style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  )),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: widget.roadmap.completedTasks / widget.roadmap.totalTasks,
                              backgroundColor: Colors.white30,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Add Task Button overlapping the header
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -32),
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TaskEditorScreen())),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.action,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.action.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                      border: Border.all(color: AppColors.background, width: 4),
                    ),
                    child: const Icon(Icons.add, color: AppColors.background, size: 32),
                  ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
                ),
              ),
            ),
          ),

          // Active Tasks
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final task = activeTasks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: _MockTaskRow(
                    task: task,
                    onToggle: () => setState(() => task.isCompleted = true),
                  ).animate().fadeIn(delay: Duration(milliseconds: 300 + (index * 50))).slideY(begin: 0.2),
                );
              },
              childCount: activeTasks.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Completed Tasks
          if (completedTasks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    initiallyExpanded: true,
                    title: Text('COMPLETED (${completedTasks.length})', 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 1.2)
                    ),
                    children: completedTasks.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _MockTaskRow(
                        task: t,
                        onToggle: () => setState(() => t.isCompleted = false),
                      ),
                    )).toList(),
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ),
            ),
            
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _MockRoadmapTask {
  final String title;
  bool isCompleted;
  _MockRoadmapTask(this.title, this.isCompleted);
}

class _MockTaskRow extends StatelessWidget {
  final _MockRoadmapTask task;
  final VoidCallback onToggle;

  const _MockTaskRow({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted ? AppColors.action : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted ? AppColors.action : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: task.isCompleted ? const Icon(Icons.check, size: 18, color: AppColors.background) : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(task.title, style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: task.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.textSecondary,
            )),
          )
        ],
      ),
    );
  }
}

