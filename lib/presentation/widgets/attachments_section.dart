import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:todow/domain/models/task.dart';
import 'package:todow/domain/models/attachment.dart';
import 'package:todow/domain/attachment_limits.dart';
import 'package:todow/presentation/controllers/task_controller.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'attachment_row.dart';

class AttachmentsSection extends StatefulWidget {
  final Task? task;

  const AttachmentsSection({super.key, required this.task});

  @override
  State<AttachmentsSection> createState() => _AttachmentsSectionState();
}

class _AttachmentsSectionState extends State<AttachmentsSection> {
  List<Attachment> _attachments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    if (widget.task == null) return;
    final controller = context.read<TaskController>();
    final attachments = await controller.getAttachments(widget.task!.id);
    if (mounted) {
      setState(() {
        _attachments = attachments;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    if (widget.task == null) return;
    
    final allowedExts = kAllowedExtensions.map((e) => e.substring(1)).toList();
    
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExts,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    if (!mounted) return;
    final controller = context.read<TaskController>();
    
    try {
      final ext = file.extension?.toLowerCase() ?? '';
      final mimeType = ext == 'pdf' ? 'application/pdf' : 
          ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(ext) ? 'image/$ext' : 'application/octet-stream';

      await controller.attachFile(widget.task!.id, file.path!, file.name, mimeType);
      _loadAttachments();
    } on FileTooLargeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } on UnsupportedFileTypeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to attach file: $e')));
      }
    }
  }
  
  Future<void> _openFile(Attachment attachment) async {
    final controller = context.read<TaskController>();
    await controller.openAttachment(attachment);
  }
  
  Future<void> _removeAttachment(Attachment attachment) async {
    final controller = context.read<TaskController>();
    await controller.removeAttachment(attachment.id);
    _loadAttachments();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.task == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ATTACHMENTS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: _pickFile,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: const Text('+ Add', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14.0),
            boxShadow: const [
              BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: _isLoading 
            ? const SizedBox(
                height: 60, 
                child: Center(child: CircularProgressIndicator(strokeWidth: 2))
              )
            : _attachments.isEmpty
              ? const SizedBox(
                  height: 60,
                  child: Center(
                    child: Text(
                      'No attachments',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _attachments.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1, 
                    thickness: 1, 
                    color: AppColors.divider, 
                    indent: 0, 
                    endIndent: 0
                  ),
                  itemBuilder: (context, index) {
                    final att = _attachments[index];
                    return Slidable(
                      key: ValueKey(att.id),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.2,
                        children: [
                          SlidableAction(
                            onPressed: (_) => _removeAttachment(att),
                            backgroundColor: AppColors.alert,
                            foregroundColor: Colors.white,
                            icon: Icons.delete_outline_rounded,
                          ),
                        ],
                      ),
                      child: AttachmentRow(
                        attachment: att,
                        onTap: () => _openFile(att),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
