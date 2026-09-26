import 'package:flutter/material.dart';
import 'package:p1ng_todo_manager/bootstrap.dart';
import 'package:p1ng_todo_manager/core/theme/app_theme.dart';
import 'package:p1ng_todo_manager/presentation/app.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const P1ngApp());
}

class P1ngApp extends StatefulWidget {
  const P1ngApp({super.key});

  @override
  State<P1ngApp> createState() => _P1ngAppState();
}

class _P1ngAppState extends State<P1ngApp> {
  late final Future<AppServices> _services = bootstrap();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P1ng',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: FutureBuilder<AppServices>(
        future: _services,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _StartupError(error: snapshot.error.toString());
          }
          if (!snapshot.hasData) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          final services = snapshot.data!;
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: services.taskController),
              ChangeNotifierProvider.value(value: services.focusController),
              ChangeNotifierProvider.value(value: services.timetableController),
              ChangeNotifierProvider.value(value: services.appController),
            ],
            child: AppShell(services: services),
          );
        },
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('P1ng could not start',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                  'Check storage and notification permissions, then restart the app.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
