import 'package:equatable/equatable.dart';

import '../utils/json_utils.dart';

/// Resolved invite attachment on a paid community (`chat_conversations` columns
/// `invite_attachment_path` / `_name` / `_mime` + optional signed URL).
class InviteAttachment extends Equatable {
  const InviteAttachment({
    required this.path,
    required this.name,
    required this.mime,
    this.signedUrl,
  });

  final String path;
  final String name;
  final String mime;
  final String? signedUrl;

  bool get isHtml =>
      mime == 'text/html' ||
      name.toLowerCase().endsWith('.html') ||
      name.toLowerCase().endsWith('.htm');

  bool get isPdf =>
      mime == 'application/pdf' || name.toLowerCase().endsWith('.pdf');

  factory InviteAttachment.fromConversationJson(Map<String, dynamic> json) {
    final path = readJson<String>(
      json,
      'invite_attachment_path',
      'inviteAttachmentPath',
    );
    if (path == null || path.isEmpty) {
      throw ArgumentError('invite attachment path is required');
    }
    return InviteAttachment(
      path: path,
      name: readJson<String>(
            json,
            'invite_attachment_name',
            'inviteAttachmentName',
          ) ??
          'Attachment',
      mime: readJson<String>(
            json,
            'invite_attachment_mime',
            'inviteAttachmentMime',
          ) ??
          'application/octet-stream',
    );
  }

  InviteAttachment copyWith({String? signedUrl}) {
    return InviteAttachment(
      path: path,
      name: name,
      mime: mime,
      signedUrl: signedUrl ?? this.signedUrl,
    );
  }

  @override
  List<Object?> get props => [path, name, mime, signedUrl];
}
