import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:p1ng_todo_manager/core/theme/app_colors.dart';
import 'package:p1ng_todo_manager/bootstrap.dart';
import 'package:p1ng_todo_manager/core/routing/app_router.dart';

class SplashScreen extends StatelessWidget {
  final AppServices services;
  const SplashScreen({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480), // Mobile width constraint
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // TOP: Logo and Interlocking Floating Pills
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo (Now much more prominent)
                      Transform.scale(
                        scale: 1.8,
                        child: Image.asset(
                          'assets/p1ng_logo_transparent.png', 
                          height: 100, 
                          fit: BoxFit.contain,
                        ).animate()
                         .fadeIn(duration: 2000.ms, curve: Curves.easeOut)
                         .slideY(begin: -0.15, end: 0, duration: 1500.ms, curve: Curves.easeOutQuint),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Interlocking Pills (Massive scale to bleed off edges)
                      // Interlocking Pills (Contained within screen edges, Fitplan staggered layout)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          return SizedBox(
                            height: 280,
                            width: w,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // 1. Roadmaps (Bottom right, side-by-side with Reminders)
                                _FloatingPill(
                                  text: "Roadmaps",
                                  color: const Color(0xFFF97316),
                                  angle: 0, 
                                  width: w * 0.435,
                                  right: 15,
                                  top: 185,
                                  delay: 500.ms,
                                ),
                                // 2. Reminders (Bottom left, side-by-side with Roadmaps)
                                _FloatingPill(
                                  text: "Reminders",
                                  color: const Color(0xFF60A5FA),
                                  angle: 0, 
                                  width: w * 0.435,
                                  left: 15,
                                  top: 185,
                                  delay: 400.ms,
                                ),
                                // 3. Smart Tasks (Middle Left)
                                _FloatingPill(
                                  text: "Smart Tasks",
                                  color: const Color(0xFFFBBF24),
                                  angle: 0, 
                                  width: w * 0.52,
                                  left: 15,
                                  top: 105,
                                  delay: 300.ms,
                                  textColor: Colors.black87,
                                ),
                                // 4. Timetables (Top Right, staggered down to fit between Focus and Smart Tasks)
                                _FloatingPill(
                                  text: "Timetables",
                                  color: const Color(0xFF4ADE80),
                                  angle: 0.12,
                                  width: w * 0.55,
                                  right: 10,
                                  top: 55,
                                  delay: 200.ms,
                                ),
                                // 5. Deep Focus (Top Left)
                                _FloatingPill(
                                  text: "Deep Focus",
                                  color: const Color(0xFFF2623E),
                                  angle: -0.12,
                                  width: w * 0.50,
                                  left: 10,
                                  top: 10,
                                  delay: 100.ms,
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // MIDDLE: Typography Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: const Text(
                    "Focus deeply.\nExecute flawlessly.",
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.15,
                      letterSpacing: -1.2,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, curve: Curves.easeOutQuart),
                ),
                
                const SizedBox(height: 56),
                
                // BOTTOM: Circular Proceed Button Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      // Circular Arrow Button
                      // Circular Arrow Button with Tactile Feedback
                      _AnimatedProceedButton(
                        onPressed: () {
                          // Impeccable smooth route transition
                          Navigator.pushReplacementNamed(context, AppRoutes.home);
                        },
                      ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 1000.ms),
                      
                      const SizedBox(height: 40),
                    ]
                  )
                )
              ]
            ),
          ),
        ),
      ),
    ),
  );
  }
}

// --- Components ---

class _FloatingPill extends StatelessWidget {
  final String text;
  final Color color;
  final double angle;
  final double? width;
  final double? left;
  final double? right;
  final double top;
  final Duration delay;
  final Color textColor;

  const _FloatingPill({
    required this.text, 
    required this.color, 
    required this.angle, 
    this.width,
    this.left,
    this.right,
    required this.top, 
    required this.delay,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18), 
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(100), 
            boxShadow: [
               BoxShadow(
                 color: Colors.black.withValues(alpha: 0.2), 
                 blurRadius: 12, 
                 offset: const Offset(0, 6)
               ),
            ]
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text, 
              style: TextStyle(
                color: textColor, 
                fontSize: 22, 
                fontWeight: FontWeight.w700, 
                letterSpacing: -0.5,
              )
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .moveY(begin: -6, end: 6, duration: 2500.ms, curve: Curves.easeInOutSine),
      ),
    ).animate()
     .scale(delay: delay, duration: 800.ms, curve: Curves.elasticOut, begin: const Offset(0.5, 0.5))
     .fadeIn(delay: delay, duration: 400.ms);
  }
}

class _AnimatedProceedButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _AnimatedProceedButton({required this.onPressed});

  @override
  State<_AnimatedProceedButton> createState() => _AnimatedProceedButtonState();
}

class _AnimatedProceedButtonState extends State<_AnimatedProceedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Future.delayed(const Duration(milliseconds: 150), widget.onPressed);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring track
              const SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
                ),
              ),
              // Segmented dark ring portion
              const SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: 0.25,
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.background), 
                ),
              ),
              // Inner Orange Button
              Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                  color: Color(0xFFF97316),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66F97316),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    )
                  ]
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

