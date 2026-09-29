import 'package:flutter/material.dart';
import 'package:todow/core/theme/app_colors.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({required this.onEnable, super.key});

  final Future<void> Function() onEnable;

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  bool _requesting = false;

  Future<void> _enable() async {
    setState(() => _requesting = true);
    try {
      await widget.onEnable();
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Not now'),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.action,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Stay on track\nwith reminders',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Allow notifications so Todow can send reminders you set for your tasks.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.alarm_outlined,
                          color: AppColors.attention, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Notifications are used for task reminders. You can choose “Not now” and keep using Todow.',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _requesting ? null : _enable,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.action,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _requesting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enable reminders'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
