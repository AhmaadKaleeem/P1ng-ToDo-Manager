enum AttachmentType { image, pdf, file }

class Attachment {
  const Attachment({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.localPath,
    required this.mimeType,
    required this.type,
    required this.createdAt,
    this.ocrReady = true,
  });

  final String id;
  final String taskId;
  final String fileName;
  final String localPath;
  final String mimeType;
  final AttachmentType type;
  final DateTime createdAt;
  final bool ocrReady;

  Map<String, Object?> toMap() => {
        'id': id,
        'task_id': taskId,
        'file_name': fileName,
        'local_path': localPath,
        'mime_type': mimeType,
        'type': type.name,
        'created_at': createdAt.toIso8601String(),
        'ocr_ready': ocrReady ? 1 : 0,
      };

  factory Attachment.fromMap(Map<String, Object?> map) => Attachment(
        id: map['id']! as String,
        taskId: map['task_id']! as String,
        fileName: map['file_name']! as String,
        localPath: map['local_path']! as String,
        mimeType: map['mime_type']! as String,
        type: AttachmentType.values.byName(map['type']! as String),
        createdAt: DateTime.parse(map['created_at']! as String),
        ocrReady: (map['ocr_ready'] as int? ?? 1) == 1,
      );
}
