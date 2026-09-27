import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/models/enums.dart';
import 'package:todow/domain/models/reminder.dart';
import 'package:todow/domain/models/attachment.dart';
import 'package:todow/presentation/controllers/task_controller.dart';
import 'package:todow/presentation/widgets/attachments_section.dart';

import 'task_controller_test.dart';

class TestAttachmentsSection extends StatelessWidget {
  final Task? task;
  final TaskController controller;

  const TestAttachmentsSection({super.key, this.task, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<TaskController>.value(
          value: controller,
          child: AttachmentsSection(task: task),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('renders "No attachments" when the list is empty', (tester) async {
    final mockRepo = MockTaskRepository();
    final controller = TaskController(mockRepo, MockReminderScheduler(), MockAttachmentRepository(), MockFileStorage());
    final task = Task(id: '1', title: 'Task', description: '', status: TaskStatus.active, priority: TaskPriority.low, createdAt: DateTime.now(), updatedAt: DateTime.now(), tags: [], reminderPlan: const ReminderPlan(preset: ReminderPreset.custom, offsets: [], constantReminder: false), sourceType: TaskSourceType.local, sortOrder: 0);
    
    await tester.pumpWidget(TestAttachmentsSection(task: task, controller: controller));
    await tester.pumpAndSettle();
    
    expect(find.text('No attachments'), findsOneWidget);
  });

  testWidgets('section is not built when widget.task == null', (tester) async {
    final mockRepo = MockTaskRepository();
    final controller = TaskController(mockRepo, MockReminderScheduler(), MockAttachmentRepository(), MockFileStorage());
    
    await tester.pumpWidget(TestAttachmentsSection(task: null, controller: controller));
    await tester.pumpAndSettle();
    
    expect(find.text('ATTACHMENTS'), findsNothing);
    expect(find.text('ATTACHMENTS'), findsNothing);
  });

  testWidgets('renders N rows for N attachments (N=2)', (tester) async {
    final mockRepo = MockTaskRepository();
    final mockAttachmentRepo = MockAttachmentRepository();
    final controller = TaskController(mockRepo, MockReminderScheduler(), mockAttachmentRepo, MockFileStorage());
    final task = Task(id: '1', title: 'Task', description: '', status: TaskStatus.active, priority: TaskPriority.low, createdAt: DateTime.now(), updatedAt: DateTime.now(), tags: [], reminderPlan: const ReminderPlan(preset: ReminderPreset.custom, offsets: [], constantReminder: false), sourceType: TaskSourceType.local, sortOrder: 0);
    
    final att1 = Attachment(id: 'att1', taskId: '1', filename: 'path.jpg', mimeType: 'image/jpeg', sizeBytes: 1024, contentHash: 'a' * 64, syncState: AttachmentSyncState.localOnly, createdAt: DateTime.now(), updatedAt: DateTime.now());
    final att2 = Attachment(id: 'att2', taskId: '1', filename: 'doc.pdf', mimeType: 'application/pdf', sizeBytes: 1024, contentHash: 'a' * 64, syncState: AttachmentSyncState.localOnly, createdAt: DateTime.now(), updatedAt: DateTime.now());
    await mockAttachmentRepo.create(att1);
    await mockAttachmentRepo.create(att2);
    
    await tester.pumpWidget(TestAttachmentsSection(task: task, controller: controller));
    await tester.pumpAndSettle();
    
    // Custom row widget assumed
    expect(find.byType(ListTile), findsNothing); // we should check for AttachmentRow
    expect(find.text('path.jpg'), findsOneWidget);
    expect(find.text('doc.pdf'), findsOneWidget);
  });

  testWidgets('[+ Add] button is present when editing', (tester) async {
    final mockRepo = MockTaskRepository();
    final controller = TaskController(mockRepo, MockReminderScheduler(), MockAttachmentRepository(), MockFileStorage());
    final task = Task(id: '1', title: 'Task', description: '', status: TaskStatus.active, priority: TaskPriority.low, createdAt: DateTime.now(), updatedAt: DateTime.now(), tags: [], reminderPlan: const ReminderPlan(preset: ReminderPreset.custom, offsets: [], constantReminder: false), sourceType: TaskSourceType.local, sortOrder: 0);
    
    await tester.pumpWidget(TestAttachmentsSection(task: task, controller: controller));
    await tester.pumpAndSettle();
    
    expect(find.text('+ Add'), findsOneWidget);
  });

  testWidgets('section label reads "ATTACHMENTS"', (tester) async {
    final mockRepo = MockTaskRepository();
    final controller = TaskController(mockRepo, MockReminderScheduler(), MockAttachmentRepository(), MockFileStorage());
    final task = Task(id: '1', title: 'Task', description: '', status: TaskStatus.active, priority: TaskPriority.low, createdAt: DateTime.now(), updatedAt: DateTime.now(), tags: [], reminderPlan: const ReminderPlan(preset: ReminderPreset.custom, offsets: [], constantReminder: false), sourceType: TaskSourceType.local, sortOrder: 0);
    
    await tester.pumpWidget(TestAttachmentsSection(task: task, controller: controller));
    await tester.pumpAndSettle();
    
    expect(find.text('ATTACHMENTS'), findsOneWidget);
  });
}
