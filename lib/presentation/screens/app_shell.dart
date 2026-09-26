import 'package:flutter/material.dart';
import 'package:p1ng_todo_manager/bootstrap.dart';
import 'package:p1ng_todo_manager/core/theme/app_colors.dart';
import 'package:p1ng_todo_manager/presentation/app.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.services, super.key});
  final AppServices services;
  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 300)
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void toggleDrawer() {
    if (_animationController.isDismissed) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayScreen(onFocus: () => setState(() {
        _index = 2;
        _animationController.reverse();
      })),
      const TasksScreen(),
      const FocusScreen(),
      const TimetableScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.surfaceElevated,
      body: Stack(
        children: [
          // Drawer Menu
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.action,
                    child: Icon(Icons.person, color: AppColors.background, size: 30),
                  ),
                  const SizedBox(height: 16),
                  const Text('Student', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 40),
                  _DrawerItem(icon: Icons.today_outlined, label: 'Today', selected: _index == 0, onTap: () { setState(() => _index = 0); toggleDrawer(); }),
                  _DrawerItem(icon: Icons.checklist_outlined, label: 'Tasks', selected: _index == 1, onTap: () { setState(() => _index = 1); toggleDrawer(); }),
                  _DrawerItem(icon: Icons.timer_outlined, label: 'Focus', selected: _index == 2, onTap: () { setState(() => _index = 2); toggleDrawer(); }),
                  _DrawerItem(icon: Icons.calendar_month_outlined, label: 'Timetable', selected: _index == 3, onTap: () { setState(() => _index = 3); toggleDrawer(); }),
                  const Spacer(),
                  const Text('Good\nConsistency', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  CustomPaint(
                    size: const Size(120, 30),
                    painter: _SparklinePainter(),
                  )
                ],
              ),
            ),
          ),
          // Main Content
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final slide = 250.0 * _animationController.value;
              final scale = 1.0 - (0.12 * _animationController.value);
              final radius = _animationController.value * 32.0;
              return Transform(
                transform: Matrix4.identity()
                  ..translate(slide)
                  ..scale(scale),
                alignment: Alignment.centerLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Container(
                    color: AppColors.background,
                    child: IgnorePointer(
                      ignoring: _animationController.value > 0.5,
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: pages[_index],
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.action : AppColors.textSecondary(), size: 22),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary(),
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.action
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..lineTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.4, size.height * 0.9)
      ..lineTo(size.width * 0.6, size.height * 0.2)
      ..lineTo(size.width * 0.8, size.height * 0.6)
      ..lineTo(size.width, size.height * 0.1);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

