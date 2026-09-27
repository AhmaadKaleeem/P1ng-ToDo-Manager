import 'package:flutter/material.dart';
import 'package:todow/bootstrap.dart';
import 'package:todow/core/theme/app_theme.dart';
import 'package:todow/core/routing/app_router.dart';
import 'package:provider/provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TodowApp()));
}

class TodowApp extends StatefulWidget {
  const TodowApp({super.key});

  @override
  State<TodowApp> createState() => _TodowAppState();
}

class _TodowAppState extends State<TodowApp> {
  late final Future<AppServices> _services = bootstrap();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppServices>(
      future: _services,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            theme: AppTheme.dark,
            home: _StartupError(error: snapshot.error.toString()),
          );
        }
        if (!snapshot.hasData) {
          return MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        
        final services = snapshot.data!;
        
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: services.taskController),
            ChangeNotifierProvider.value(value: services.focusController),
            ChangeNotifierProvider.value(value: services.timetableController),
            ChangeNotifierProvider.value(value: services.appController),
          ],
          child: MaterialApp(
            title: 'Todow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: (settings) => AppRouter.generateRoute(settings, services),
          ),
        );
      },
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
              Text('Todow could not start',
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
