import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:todow/bootstrap.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'package:todow/presentation/app.dart';
import 'package:todow/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.services, super.key});
  final AppServices services;
  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> with TickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _animationController;
  ui.FragmentProgram? _program;
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier(0.0);
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 300),
    );
    _loadShader();
    _ticker = createTicker((elapsed) {
      if (_animationController.value > 0.001) {
        _time.value += 0.016; // Simulate ~60fps progression
      }
    });
    _ticker.start();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/void.frag');
      setState(() {
        _program = program;
      });
    } catch (e) {
      debugPrint('Failed to load void shader: $e');
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void toggleDrawer() {
    final spring = SpringDescription(
      mass: 1.0,
      stiffness: 120.0,
      damping: 14.0,
    );
    
    if (_animationController.isDismissed || _animationController.status == AnimationStatus.reverse) {
      _animationController.animateWith(SpringSimulation(spring, _animationController.value, 1.0, _animationController.velocity));
    } else {
      _animationController.animateWith(SpringSimulation(spring, _animationController.value, 0.0, _animationController.velocity));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const TasksScreen(),
      const FocusScreen(),
      const TimetableScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.surfaceElevated,
      body: Stack(
        children: [
          // Shader Void Background
          if (_program != null)
            AnimatedBuilder(
              animation: _time,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _VoidShaderPainter(_program!, _time.value),
                );
              }
            ),
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
                  FutureBuilder<SharedPreferences>(
                    future: SharedPreferences.getInstance(),
                    builder: (context, snapshot) {
                      final name = snapshot.data?.getString('username') ?? 'Student';
                      return Text('Welcome, $name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary));
                    }
                  ),
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
              final slide = 280.0 * _animationController.value;
              final scale = 1.0 - (0.15 * _animationController.value);
              final radius = _animationController.value * 32.0;
              final rotateY = -0.25 * _animationController.value;
              
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // True 3D perspective
                  ..translate(slide, 0.0, 0.0)
                  ..scale(scale)
                  ..rotateY(rotateY),
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
            Icon(icon, color: selected ? AppColors.action : AppColors.textSecondary, size: 22),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
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

class _VoidShaderPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;

  _VoidShaderPainter(this.program, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _VoidShaderPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

