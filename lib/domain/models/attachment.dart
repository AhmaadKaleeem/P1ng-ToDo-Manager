enum AttachmentSyncState {
  localOnly,
  pendingUpload,
  uploading,
  uploaded,
  uploadFailed,
}

class Attachment {
  Attachment({
    required this.id,
    required this.taskId,
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
    required this.contentHash,
    required this.syncState,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.remoteUploadId,
  })  : assert(id.isNotEmpty, 'id must not be empty'),
        assert(taskId.isNotEmpty, 'taskId must not be empty'),
        assert(filename.isNotEmpty, 'filename must not be empty'),
        assert(sizeBytes >= 0, 'sizeBytes must be >= 0'),
        assert(
          contentHash.length == 64 && _isHex(contentHash),
          'contentHash must be 64 hex chars',
        );

  final String id;
  final String taskId;
  final String filename;
  final String mimeType;
  final int sizeBytes;
  final String contentHash;
  final AttachmentSyncState syncState;
  final String? remoteId;
  final String? remoteUploadId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Attachment copyWith({
    String? id,
    String? taskId,
    String? filename,
    String? mimeType,
    int? sizeBytes,
    String? contentHash,
    AttachmentSyncState? syncState,
    String? remoteId,
    String? remoteUploadId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Attachment(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        filename: filename ?? this.filename,
        mimeType: mimeType ?? this.mimeType,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        contentHash: contentHash ?? this.contentHash,
        syncState: syncState ?? this.syncState,
        remoteId: remoteId ?? this.remoteId,
        remoteUploadId: remoteUploadId ?? this.remoteUploadId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'task_id': taskId,
        'filename': filename,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'content_hash': contentHash,
        'sync_state': syncState.name,
        'remote_id': remoteId,
        'remote_upload_id': remoteUploadId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Attachment.fromMap(Map<String, Object?> map) => Attachment(
        id: map['id']! as String,
        taskId: map['task_id']! as String,
        filename: map['filename']! as String,
        mimeType: map['mime_type']! as String,
        sizeBytes: map['size_bytes']! as int,
        contentHash: map['content_hash']! as String,
        syncState: AttachmentSyncState.values.byName(
          map['sync_state'] as String? ?? 'localOnly',
        ),
        remoteId: map['remote_id'] as String?,
        remoteUploadId: map['remote_upload_id'] as String?,
        createdAt: DateTime.parse(map['created_at']! as String),
        updatedAt: DateTime.parse(map['updated_at']! as String),
      );

  static bool _isHex(String s) =>
      RegExp(r'^[0-9a-f]+$', caseSensitive: false).hasMatch(s);
}

// Legacy type alias kept so task.dart compile doesn't break during migration.
// Remove once task.dart attachment list is typed to the new Attachment.
enum AttachmentType { image, pdf, file }
