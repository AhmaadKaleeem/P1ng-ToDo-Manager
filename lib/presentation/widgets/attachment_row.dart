import 'package:flutter/material.dart';
import 'package:todow/core/theme/app_colors.dart';
import 'package:todow/domain/models/attachment.dart';

class AttachmentRow extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback? onTap;

  const AttachmentRow({
    super.key,
    required this.attachment,
    this.onTap,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Color _getIconColor(String mimeType) {
    if (mimeType.startsWith('image/')) return AppColors.attention;
    if (mimeType == 'application/pdf') return AppColors.alert;
    return AppColors.textSecondary;
  }

  IconData _getIconData(String mimeType) {
    if (mimeType.startsWith('image/')) return Icons.image_outlined;
    if (mimeType == 'application/pdf') return Icons.picture_as_pdf_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60.0,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(
              _getIconData(attachment.mimeType),
              size: 24.0,
              color: _getIconColor(attachment.mimeType),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    attachment.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _formatSize(attachment.sizeBytes),
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20.0), // Reserved for future sync badge
          ],
        ),
      ),
    );
  }
}
