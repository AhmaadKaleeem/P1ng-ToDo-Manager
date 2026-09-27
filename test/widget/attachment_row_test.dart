import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'package:todow/domain/models/attachment.dart';
import 'package:todow/presentation/widgets/attachment_row.dart';

void main() {
  Widget buildRow(String filename, String mimeType) {
    final attachment = Attachment(
      id: 'att-1',
      taskId: 'task-1',
      filename: filename,
      mimeType: mimeType,
      sizeBytes: 1024,
      contentHash: 'a' * 64,
      syncState: AttachmentSyncState.localOnly,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return MaterialApp(
      home: Scaffold(
        body: AttachmentRow(attachment: attachment),
      ),
    );
  }

  testWidgets('renders icon in AppColors.attention for .jpg filename', (tester) async {
    await tester.pumpWidget(buildRow('image.jpg', 'image/jpeg'));
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, AppColors.attention);
  });

  testWidgets('renders icon in AppColors.alert for .pdf filename', (tester) async {
    await tester.pumpWidget(buildRow('doc.pdf', 'application/pdf'));
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, AppColors.alert);
  });

  testWidgets('renders icon in AppColors.textSecondary for .docx filename', (tester) async {
    await tester.pumpWidget(buildRow('doc.docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'));
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, AppColors.textSecondary);
  });

  testWidgets('row height is 60.0', (tester) async {
    await tester.pumpWidget(buildRow('file.txt', 'text/plain'));
    final size = tester.getSize(find.byType(AttachmentRow));
    expect(size.height, 60.0);
  });

  testWidgets('long filename activates ellipsis', (tester) async {
    final longName = 'this_is_a_very_long_filename_that_should_trigger_ellipsis_in_the_ui.txt';
    await tester.pumpWidget(buildRow(longName, 'text/plain'));
    final text = tester.widget<Text>(find.text(longName));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('right side reserves 20dp empty slot', (tester) async {
    await tester.pumpWidget(buildRow('file.txt', 'text/plain'));
    final sizedBox = tester.widgetList<SizedBox>(find.byType(SizedBox)).firstWhere((b) => b.width == 20.0);
    expect(sizedBox, isNotNull);
  });
}
