import 'package:equatable/equatable.dart';

import '../utils/json_utils.dart';

enum AttachmentKind {
  image,
  voiceNote,
  file;

  String toJson() => switch (this) {
        AttachmentKind.image => 'image',
        AttachmentKind.voiceNote => 'voice_note',
        AttachmentKind.file => 'file',
      };

  static AttachmentKind fromJson(String value) => switch (value) {
        'image' => AttachmentKind.image,
        'voice_note' => AttachmentKind.voiceNote,
        'file' => AttachmentKind.file,
        _ => AttachmentKind.file,
      };
}

/// Mirrors `chat_message_attachments`.
class MessageAttachment extends Equatable {
  const MessageAttachment({
    required this.id,
    required this.messageId,
    required this.kind,
    required this.storagePath,
    this.durationMs,
    this.widthPx,
    this.heightPx,
    this.fileSizeBytes,
    this.originalFileName,
  });

  final String id;
  final String messageId;
  final AttachmentKind kind;
  final String storagePath;
  final int? durationMs;
  final int? widthPx;
  final int? heightPx;

  /// Not persisted in schema — used for optimistic UI and file chips.
  final int? fileSizeBytes;

  /// Not persisted in schema — preserved from pick result when available.
  final String? originalFileName;

  String get displayName {
    if (originalFileName != null && originalFileName!.isNotEmpty) {
      return originalFileName!;
    }
    final segments = storagePath.split('/');
    return segments.isNotEmpty ? segments.last : storagePath;
  }

  String get extension {
    final name = displayName;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) {
      return '';
    }
    return name.substring(dot + 1).toLowerCase();
  }

  bool get isHtml =>
      kind == AttachmentKind.file &&
      (extension == 'html' || extension == 'htm');

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: requireString(json, 'id', 'id'),
      messageId: requireString(json, 'message_id', 'messageId'),
      kind: AttachmentKind.fromJson(
        readJson<String>(json, 'kind', 'kind') ?? 'file',
      ),
      storagePath:
          requireString(json, 'storage_path', 'storagePath'),
      durationMs: readInt(json, 'duration_ms', 'durationMs'),
      widthPx: readInt(json, 'width_px', 'widthPx'),
      heightPx: readInt(json, 'height_px', 'heightPx'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'message_id': messageId,
        'kind': kind.toJson(),
        'storage_path': storagePath,
        'duration_ms': durationMs,
        'width_px': widthPx,
        'height_px': heightPx,
      };

  MessageAttachment copyWith({
    String? id,
    String? messageId,
    AttachmentKind? kind,
    String? storagePath,
    int? durationMs,
    int? widthPx,
    int? heightPx,
    int? fileSizeBytes,
    String? originalFileName,
  }) {
    return MessageAttachment(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      kind: kind ?? this.kind,
      storagePath: storagePath ?? this.storagePath,
      durationMs: durationMs ?? this.durationMs,
      widthPx: widthPx ?? this.widthPx,
      heightPx: heightPx ?? this.heightPx,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      originalFileName: originalFileName ?? this.originalFileName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        messageId,
        kind,
        storagePath,
        durationMs,
        widthPx,
        heightPx,
        fileSizeBytes,
        originalFileName,
      ];
}
