import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:p1ng_todo_manager/core/theme/app_colors.dart';
import 'dart:ui' show ImageFilter;

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({this.onFocus, super.key});
  final VoidCallback? onFocus;

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _isOverlayActive = false;

  void _toggleOverlay() {
    setState(() {
      _isOverlayActive = !_isOverlayActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Stack(
            children: [
              // MAIN CANVAS LAYER
              // It scales back and blurs when the overlay is active (Physical Layers)
              AnimatedScale(
                scale: _isOverlayActive ? 0.9 : 1.0,
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _isOverlayActive ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (context, val, child) {
                    return ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: val * 10, sigmaY: val * 10),
                      child: Container(
                        foregroundDecoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: val * 0.4),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 60)),
                      
                      // Top App Bar
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _TactileTap(
                                onTap: () {},
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceElevated,
                                  ),
                                  child: const Icon(Icons.person_outline, color: AppColors.textPrimary),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _TactileTap(
                                    onTap: () {},
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.divider),
                                      ),
                                      child: const Icon(Icons.search, color: AppColors.textPrimary, size: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _TactileTap(
                                    onTap: () {},
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.divider),
                                      ),
                                      child: const Icon(Icons.more_horiz, color: AppColors.textPrimary, size: 22),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.5, curve: Curves.easeOutQuint),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 40)),

                      // Title
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        sliver: SliverToBoxAdapter(
                          child: const Text("My Tasks", style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          )).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      // Pill Tabs
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 48,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            children: const [
                              _PillTab(title: "Notebooks", icon: Icons.book_outlined),
                              _PillTab(title: "My Tasks", icon: Icons.task_alt, badge: 17, isSelected: true),
                              _PillTab(title: "Timetable", icon: Icons.calendar_month_outlined),
                            ].animate(interval: 100.ms).fadeIn(duration: 500.ms).slideX(begin: 0.2, curve: Curves.easeOutBack),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 40)),

                      // Section: Active Task (Focus Mode)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        sliver: SliverToBoxAdapter(
                          child: const Text("Active Task", style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          )).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 16)),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 170,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            children: const [
                              _ActiveTaskCard(
                                title: "40-min Breathe & Stretch",
                                progress: 0.8,
                                color: AppColors.action,
                              ),
                              _ActiveTaskCard(
                                title: "20-min Evening Walk",
                                progress: 0.92,
                                color: AppColors.alert,
                              ),
                              _ActiveTaskCard(
                                title: "Collecting Design System",
                                progress: 0.45,
                                color: Color(0xFF6366F1), // Indigo
                              ),
                            ].animate(interval: 150.ms, delay: 200.ms).fadeIn().scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 1000.ms),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 40)),

                      // Section: New Tasks
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        sliver: SliverToBoxAdapter(
                          child: const Text("New Tasks", style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          )).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 16)),

                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: const [
                              _NewTaskRow(
                                title: "Write Meeting Agenda..",
                                subtitle: "List discussion points and decisions to a clear roadmap...",
                                isCompleted: true,
                              ),
                              _NewTaskRow(
                                title: "Sketch Ten UIScreen..",
                                subtitle: "15 days in your hands to master design. Otherwise, terminated.",
                                isCompleted: false,
                              ),
                            ].animate(interval: 150.ms, delay: 350.ms).fadeIn().slideY(begin: 0.1, curve: Curves.easeOutBack, duration: 600.ms),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 40)),

                      // Section: Timetable
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        sliver: SliverToBoxAdapter(
                          child: const Text("My Calendar", style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          )).animate().fadeIn(delay: 450.ms),
                        ),
                      ),
                      
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        sliver: SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            child: const Text("January 17, 2027", style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF3F4F6),
                            )).animate().fadeIn(delay: 500.ms),
                          ),
                        ),
                      ),

                      // Horizontal Date Selector
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 80,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            children: const [
                              _DateSelector(day: "T", date: "15"),
                              _DateSelector(day: "W", date: "16"),
                              _DateSelector(day: "T", date: "17", isSelected: true),
                              _DateSelector(day: "F", date: "18"),
                              _DateSelector(day: "S", date: "19"),
                            ].animate(interval: 50.ms, delay: 550.ms).fadeIn().slideY(begin: 0.2, curve: Curves.easeOutBack, duration: 600.ms),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 32)),

                      // Timeline Events
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: const [
                              _TimetableEvent(
                                timeText: "08:30",
                                period: "AM",
                                title: "60min Push-up & Stretching..",
                                durationText: "08:30 AM - 9:30 AM",
                                highlight: AppColors.action,
                              ),
                              _TimetableEvent(
                                timeText: "11:31",
                                period: "AM",
                                title: "Schedule Client Meeting..",
                                durationText: "11:31 AM - 1:00 PM",
                                highlight: Color(0xFF6366F1), // Indigo
                              ),
                              
                              _TimelineBreak(text: "Break 1hr", timeRange: "01:00 PM - 2:00 PM"),
                              
                              _TimetableEvent(
                                timeText: "02:30",
                                period: "PM",
                                title: "Share Concepts with Dev..",
                                durationText: "02:30 PM - 4:30 PM",
                                highlight: AppColors.alert,
                              ),
                            ].animate(interval: 200.ms, delay: 600.ms).fadeIn().slideY(begin: 0.2, curve: Curves.easeOutCirc, duration: 700.ms),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                ),
              ),

              // OVERLAY LAYER
              // The new UI that springs forward when FAB is tapped
              if (_isOverlayActive)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleOverlay,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {}, // Prevent closing when tapping inside the card
                        child: Container(
                          width: 320,
                          height: 400,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: AppColors.divider, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.action.withValues(alpha: 0.2),
                                blurRadius: 60,
                                spreadRadius: 10,
                                offset: const Offset(0, 20),
                              )
                            ]
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.rocket_launch, size: 64, color: AppColors.action).animate().scale(curve: Curves.elasticOut, duration: 1000.ms, delay: 200.ms),
                              const SizedBox(height: 24),
                              const Text("Launch Task", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 16),
                              const Text("This creates a tactile 3D morph effect, pushing the timeline backwards.", 
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF9CA3AF), height: 1.5)
                              ),
                            ],
                          ),
                        ).animate().scale(
                          begin: const Offset(0.4, 0.4),
                          curve: Curves.elasticOut,
                          duration: 1200.ms,
                        ).fadeIn(),
                      ),
                    ),
                  ),
                ),

              // BOTTOM NAVIGATION
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: _FloatingNav(onAddTap: _toggleOverlay),
                ).animate(target: _isOverlayActive ? 1 : 0).slideY(end: 1.5, duration: 400.ms, curve: Curves.easeInBack),
                // Notice how the nav elegantly slides out of the way when the overlay is active!
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- Tactile Interaction Wrapper ---
class _TactileTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TactileTap({required this.child, required this.onTap});

  @override
  State<_TactileTap> createState() => _TactileTapState();
}

class _TactileTapState extends State<_TactileTap> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isDown = true),
      onTapUp: (_) {
        setState(() => _isDown = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isDown = false),
      child: AnimatedScale(
        scale: _isDown ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}

// --- Components ---

class _PillTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? badge;
  final bool isSelected;

  const _PillTab({required this.title, required this.icon, this.badge, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return _TactileTap(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.action.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.action : AppColors.divider,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.action : AppColors.textSecondary(0.8)),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? AppColors.action : AppColors.textPrimary
            )),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.action : AppColors.divider,
                  shape: BoxShape.circle,
                ),
                child: Text(badge.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.background, height: 1.0)),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class _ActiveTaskCard extends StatelessWidget {
  final String title;
  final double progress;
  final Color color;

  const _ActiveTaskCard({required this.title, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return _TactileTap(
      onTap: () {},
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.3, color: AppColors.textPrimary)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Progress", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
                Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2))
                    ]
                  ),
                ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.3)), // Breathing liquid animation
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _NewTaskRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;

  const _NewTaskRow({required this.title, required this.subtitle, this.isCompleted = false});

  @override
  Widget build(BuildContext context) {
    return _TactileTap(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.action : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCompleted ? AppColors.action : const Color(0xFF9CA3AF),
                  width: 2,
                )
              ),
              child: isCompleted ? const Icon(Icons.check, size: 18, color: AppColors.background) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w800, 
                    color: AppColors.textPrimary, 
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: const Color(0xFF9CA3AF),
                  )),
                  const SizedBox(height: 8),
                  const Text("List discussion points and decisions to a clear roadmap...", style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF9CA3AF))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String day;
  final String date;
  final bool isSelected;

  const _DateSelector({required this.day, required this.date, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return _TactileTap(
      onTap: () {},
      child: Container(
        width: 60,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.action.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isSelected ? AppColors.action : Colors.transparent,
            width: 1.5,
          )
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(day, style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w700, 
              color: isSelected ? AppColors.action : AppColors.textPrimary
            )),
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.action : AppColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Text(date, style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.w800, 
                color: isSelected ? AppColors.background : const Color(0xFF9CA3AF)
              )),
            )
          ],
        ),
      ),
    );
  }
}

class _TimetableEvent extends StatelessWidget {
  final String timeText;
  final String period;
  final String title;
  final String durationText;
  final Color highlight;

  const _TimetableEvent({required this.timeText, required this.period, required this.title, required this.durationText, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return _TactileTap(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(timeText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  const Text("AM", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF))),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0, top: 0, bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: highlight,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                             BoxShadow(color: highlight.withValues(alpha: 0.5), blurRadius: 4)
                          ]
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.3)),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: highlight.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(durationText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: highlight)),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _TimelineBreak extends StatelessWidget {
  final String text;
  final String timeRange;

  const _TimelineBreak({required this.text, required this.timeRange});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 45,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.play_arrow, size: 14, color: Color(0xFF9CA3AF)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                Expanded(
                  child: Container(
                    height: 1.5,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: AppColors.divider,
                  ),
                ),
                const Text("01:00 PM - 2:00 PM", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  final VoidCallback onAddTap;
  const _FloatingNav({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.divider, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 15),
          )
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add button with tactile feedback
          _TactileTap(
            onTap: onAddTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.add, color: AppColors.textPrimary, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(icon: const Icon(Icons.task_alt, color: AppColors.textPrimary, size: 24), onPressed: () {}),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.book_outlined, color: AppColors.textPrimary, size: 24), onPressed: () {}),
          const SizedBox(width: 8),
          // Active Tab
          _TactileTap(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.action.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.action.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: AppColors.action, size: 20),
                  const SizedBox(width: 8),
                  const Text("Calend", style: TextStyle(color: AppColors.action, fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

