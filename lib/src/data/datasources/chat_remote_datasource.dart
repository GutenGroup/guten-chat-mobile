import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import '../../domain/models/message_attachment.dart';
import '../../domain/models/participant.dart';
import '../../domain/models/payment_request.dart';
import '../../domain/models/reaction.dart';
import '../../domain/models/tip.dart';
import '../../domain/repositories/chat_repository.dart';

/// Low-level Supabase access to `chat_*` tables and SECURITY DEFINER RPCs.
class ChatRemoteDataSource {
  ChatRemoteDataSource(this.client);

  final SupabaseClient client;

  static const _attachmentsBucket = 'chat-attachments';
  static const _messageSelect =
      '*, chat_message_reactions(*), chat_message_attachments(*), chat_payment_requests(*)';

  Future<String> getCurrentProfileId() async {
    try {
      final response = await client.rpc('chat_current_profile_id');
      if (response is String && response.isNotEmpty) {
        return response;
      }
    } on PostgrestException {
      // Host may not expose the RPC (e.g. PGRST202); fall back to auth uid.
    }
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Not authenticated');
    }
    return userId;
  }

  Future<List<Conversation>> fetchConversations() async {
    final rows = await client
        .from('chat_conversations')
        .select('*, chat_conversation_participants!inner(*)')
        .order('last_message_at', ascending: false);

    return (rows as List<dynamic>)
        .map((row) => Conversation.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Conversation> fetchConversation(String conversationId) async {
    final row = await client
        .from('chat_conversations')
        .select()
        .eq('id', conversationId)
        .single();
    return Conversation.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<Participant>> fetchParticipants(String conversationId) async {
    final rows = await client
        .from('chat_conversation_participants')
        .select()
        .eq('conversation_id', conversationId);
    return (rows as List<dynamic>)
        .map((row) => Participant.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<Message>> fetchMessages(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  }) async {
    var filter = client
        .from('chat_messages')
        .select(_messageSelect)
        .eq('conversation_id', conversationId);

    if (before != null) {
      filter = filter.lt('created_at', before.toIso8601String());
    }

    final rows = await filter
        .order('created_at', ascending: false)
        .limit(limit);
    final messages = (rows as List<dynamic>)
        .map((row) => Message.fromJson(Map<String, dynamic>.from(row)))
        .toList();
    return messages.reversed.toList();
  }

  Future<String> createDm(String otherProfileId) async {
    final response = await client.rpc(
      'chat_create_dm',
      params: {'other_profile_id': otherProfileId},
    );
    if (response is String) {
      return response;
    }
    if (response is Map && response['conversation_id'] != null) {
      return response['conversation_id'].toString();
    }
    return response.toString();
  }

  Future<String> createGroup({
    required String title,
    required List<String> memberProfileIds,
    String? imageUrl,
    bool isPaid = false,
    int? joinPriceCents,
    String? joinCurrency,
  }) async {
    final response = await client.rpc(
      'chat_create_group',
      params: {
        'title': title,
        'member_profile_ids': memberProfileIds,
        'image_url': imageUrl,
        'is_paid': isPaid,
        'join_price_cents': joinPriceCents,
        'join_currency': joinCurrency,
      },
    );
    if (response is String) {
      return response;
    }
    if (response is Map && response['conversation_id'] != null) {
      return response['conversation_id'].toString();
    }
    return response.toString();
  }

  Future<void> addGroupMember(String conversationId, String profileId) async {
    await client.rpc(
      'chat_add_group_member',
      params: {
        'conversation_id': conversationId,
        'profile_id': profileId,
      },
    );
  }

  Future<void> removeGroupMember(
    String conversationId,
    String profileId,
  ) async {
    await client.rpc(
      'chat_remove_group_member',
      params: {
        'conversation_id': conversationId,
        'profile_id': profileId,
      },
    );
  }

  Future<void> leaveGroup(String conversationId) async {
    await client.rpc(
      'chat_leave_group',
      params: {'conversation_id': conversationId},
    );
  }

  Future<void> setGroupRole(
    String conversationId,
    String profileId,
    ParticipantRole role,
  ) async {
    await client.rpc(
      'chat_set_group_role',
      params: {
        'conversation_id': conversationId,
        'profile_id': profileId,
        'role': role.toJson(),
      },
    );
  }

  Future<void> joinGroup(String conversationId) async {
    await client.rpc(
      'chat_join_group',
      params: {'conversation_id': conversationId},
    );
  }

  Future<Message> _fetchMessage(String messageId) async {
    final row = await client
        .from('chat_messages')
        .select(_messageSelect)
        .eq('id', messageId)
        .single();
    return Message.fromJson(Map<String, dynamic>.from(row));
  }

  Future<String> createSignedAttachmentUrl(String storagePath) async {
    return client.storage
        .from(_attachmentsBucket)
        .createSignedUrl(storagePath, 3600);
  }

  Future<List<int>> downloadAttachmentBytes(String storagePath) async {
    return client.storage.from(_attachmentsBucket).download(storagePath);
  }

  Future<Message> sendAttachment({
    required String conversationId,
    required String localPath,
    required AttachmentKind kind,
    String? caption,
    String? fileName,
    int? widthPx,
    int? heightPx,
    int? fileSizeBytes,
    int? durationMs,
    String? clientTempId,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw StateError('Attachment file not found');
    }

    final bytes = await file.readAsBytes();
    final resolvedName = fileName ?? localPath.split('/').last;
    final ext = _extensionFor(resolvedName, kind);
    final storagePath = '$conversationId/${const Uuid().v4()}.$ext';
    final contentType = _contentTypeFor(ext);

    onProgress?.call(0.05);
    await client.storage.from(_attachmentsBucket).uploadBinary(
          storagePath,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    onProgress?.call(0.65);

    final trimmedCaption = caption?.trim();
    final messageRow = await client
        .from('chat_messages')
        .insert({
          'conversation_id': conversationId,
          if (trimmedCaption != null && trimmedCaption.isNotEmpty)
            'body_md': trimmedCaption,
          if (clientTempId != null) 'client_temp_id': clientTempId,
        })
        .select()
        .single();

    final messageId = messageRow['id'].toString();

    await client.from('chat_message_attachments').insert({
      'message_id': messageId,
      'kind': kind.toJson(),
      'storage_path': storagePath,
      if (widthPx != null) 'width_px': widthPx,
      if (heightPx != null) 'height_px': heightPx,
      if (durationMs != null) 'duration_ms': durationMs,
    });

    onProgress?.call(1);

    final message = await _fetchMessage(messageId);
    if (message.attachments.isEmpty) {
      return message.copyWith(
        attachments: [
          MessageAttachment(
            id: 'local-$messageId',
            messageId: messageId,
            kind: kind,
            storagePath: storagePath,
            widthPx: widthPx,
            heightPx: heightPx,
            fileSizeBytes: fileSizeBytes ?? bytes.length,
            originalFileName: resolvedName,
            durationMs: durationMs,
          ),
        ],
      );
    }

    return message.copyWith(
      attachments: message.attachments
          .map(
            (attachment) => attachment.copyWith(
              fileSizeBytes: fileSizeBytes ?? bytes.length,
              originalFileName: resolvedName,
            ),
          )
          .toList(),
    );
  }

  String _extensionFor(String fileName, AttachmentKind kind) {
    final dot = fileName.lastIndexOf('.');
    if (dot > 0 && dot < fileName.length - 1) {
      return fileName.substring(dot + 1).toLowerCase();
    }
    return switch (kind) {
      AttachmentKind.image => 'jpg',
      AttachmentKind.voiceNote => 'm4a',
      AttachmentKind.file => 'bin',
    };
  }

  String _contentTypeFor(String ext) {
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'html' || 'htm' => 'text/html',
      'pdf' => 'application/pdf',
      'm4a' => 'audio/mp4',
      _ => 'application/octet-stream',
    };
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await client.rpc(
        'chat_delete_message',
        params: {'message_id': messageId},
      );
    } catch (_) {
      await client.from('chat_messages').delete().eq('id', messageId);
    }
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String body,
    String? replyToMessageId,
    String? clientTempId,
  }) async {
    final response = await client.rpc(
      'chat_send_message',
      params: {
        'conversation_id': conversationId,
        'body': body,
        'reply_to_message_id': replyToMessageId,
        'client_temp_id': clientTempId,
      },
    );

    if (response is Map<String, dynamic>) {
      return Message.fromJson(response);
    }
    if (response is Map) {
      return Message.fromJson(Map<String, dynamic>.from(response));
    }

    // Some RPCs return only the id; fetch the full row.
    final messageId = response.toString();
    final row = await client
        .from('chat_messages')
        .select(_messageSelect)
        .eq('id', messageId)
        .single();
    return Message.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<Reaction>> toggleReaction({
    required String messageId,
    required String value,
    required ReactionKind kind,
  }) async {
    final response = await client.rpc(
      'chat_toggle_reaction',
      params: {
        'message_id': messageId,
        'value': value,
        'kind': kind.toJson(),
      },
    );

    if (response is List) {
      return response
          .whereType<Map>()
          .map((row) => Reaction.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    }

    final rows = await client
        .from('chat_message_reactions')
        .select()
        .eq('message_id', messageId);
    return (rows as List<dynamic>)
        .map((row) => Reaction.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> markRead(String conversationId, {String? messageId}) async {
    await client.rpc(
      'chat_mark_read',
      params: {
        'conversation_id': conversationId,
        'message_id': messageId,
      },
    );
  }

  Future<PaymentRequest> createPaymentRequest({
    required String conversationId,
    required int amountCents,
    required String currency,
    String? note,
    String? messageId,
  }) async {
    final response = await client.rpc(
      'chat_create_payment_request',
      params: {
        'conversation_id': conversationId,
        'amount_cents': amountCents,
        'currency': currency,
        'note': note,
        'message_id': messageId,
      },
    );
    if (response is Map<String, dynamic>) {
      return PaymentRequest.fromJson(response);
    }
    return PaymentRequest.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<Tip> sendTip({
    required String conversationId,
    required String recipientProfileId,
    required int amountCents,
    required String currency,
    String? note,
    String? messageId,
  }) async {
    final response = await client.rpc(
      'chat_send_tip',
      params: {
        'conversation_id': conversationId,
        'recipient_profile_id': recipientProfileId,
        'amount_cents': amountCents,
        'currency': currency,
        'note': note,
        'message_id': messageId,
      },
    );
    if (response is Map<String, dynamic>) {
      return Tip.fromJson(response);
    }
    return Tip.fromJson(Map<String, dynamic>.from(response as Map));
  }
}

/// Realtime channel mirroring web `ConversationChannel`.
class ConversationChannel {
  ConversationChannel({
    required this.client,
    required String conversationId,
    required String currentProfileId,
  })  : _conversationId = conversationId,
        _currentProfileId = currentProfileId;

  final SupabaseClient client;
  final String _conversationId;
  final String _currentProfileId;

  RealtimeChannel? _channel;
  final _controller = StreamController<ConversationEvent>.broadcast();
  Timer? _typingClearTimer;
  final _typingProfileIds = <String>{};
  final _onlineProfileIds = <String>{};

  static const _typingTtl = Duration(seconds: 4);

  Stream<ConversationEvent> get stream => _controller.stream;

  Future<void> subscribe() async {
    _channel = client.channel('chat:$_conversationId');

    _channel!
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chat_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'conversation_id',
          value: _conversationId,
        ),
        callback: (payload) async {
          final record = payload.newRecord;
          if (record.isEmpty) {
            return;
          }
          if (payload.eventType == PostgresChangeEvent.insert) {
            final messageId = record['id']?.toString();
            if (messageId != null) {
              try {
                final message = await client
                    .from('chat_messages')
                    .select(
                      '*, chat_message_reactions(*), chat_message_attachments(*), chat_payment_requests(*)',
                    )
                    .eq('id', messageId)
                    .single();
                _controller.add(
                  MessageInserted(
                    Message.fromJson(Map<String, dynamic>.from(message)),
                  ),
                );
                return;
              } catch (_) {
                // Fall back to bare row below.
              }
            }
          }
          final message = Message.fromJson(Map<String, dynamic>.from(record));
          if (payload.eventType == PostgresChangeEvent.insert) {
            _controller.add(MessageInserted(message));
          } else {
            _controller.add(MessageUpdated(message));
          }
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chat_message_reactions',
        callback: (payload) async {
          final record = payload.newRecord.isNotEmpty
              ? payload.newRecord
              : payload.oldRecord;
          final messageId = record['message_id']?.toString();
          if (messageId == null) {
            return;
          }
          final rows = await client
              .from('chat_message_reactions')
              .select()
              .eq('message_id', messageId);
          final reactions = (rows as List<dynamic>)
              .map((row) => Reaction.fromJson(Map<String, dynamic>.from(row)))
              .toList();
          _controller.add(
            ReactionChanged(messageId: messageId, reactions: reactions),
          );
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chat_payment_requests',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'conversation_id',
          value: _conversationId,
        ),
        callback: (payload) async {
          final record = payload.newRecord.isNotEmpty
              ? payload.newRecord
              : payload.oldRecord;
          final messageId = record['message_id']?.toString();
          if (messageId == null) {
            return;
          }
          try {
            final message = await client
                .from('chat_messages')
                .select(
                  '*, chat_message_reactions(*), chat_message_attachments(*), chat_payment_requests(*)',
                )
                .eq('id', messageId)
                .single();
            _controller.add(
              MessageUpdated(
                Message.fromJson(Map<String, dynamic>.from(message)),
              ),
            );
          } catch (_) {
            // Ignore — message may not exist yet.
          }
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'chat_conversation_participants',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'conversation_id',
          value: _conversationId,
        ),
        callback: (payload) async {
          final rows = await client
              .from('chat_conversation_participants')
              .select()
              .eq('conversation_id', _conversationId);
          final participants = (rows as List<dynamic>)
              .map((row) => Participant.fromJson(Map<String, dynamic>.from(row)))
              .toList();
          _controller.add(ReadReceiptsChanged(participants));
        },
      )
      ..onBroadcast(
        event: 'typing',
        callback: (payload) {
          final profileId = payload['profile_id']?.toString();
          final isTyping = payload['is_typing'] == true;
          if (profileId == null || profileId == _currentProfileId) {
            return;
          }
          if (isTyping) {
            _typingProfileIds.add(profileId);
          } else {
            _typingProfileIds.remove(profileId);
          }
          _controller.add(TypingChanged(_typingProfileIds.toList()));
          _scheduleTypingClear(profileId);
        },
      )
      ..onPresenceSync((_) {
        final state = _channel!.presenceState();
        _onlineProfileIds
          ..clear()
          ..addAll(
            state
                .expand((presence) => presence.presences)
                .map((p) => p.payload['profile_id']?.toString())
                .whereType<String>(),
          );
        _controller.add(PresenceChanged(_onlineProfileIds.toSet()));
      });

    _channel!.subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel!.track({'profile_id': _currentProfileId});
      }
    });
  }

  void _scheduleTypingClear(String profileId) {
    _typingClearTimer?.cancel();
    _typingClearTimer = Timer(_typingTtl, () {
      _typingProfileIds.remove(profileId);
      _controller.add(TypingChanged(_typingProfileIds.toList()));
    });
  }

  Future<void> broadcastTyping(bool isTyping) async {
    await _channel?.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'profile_id': _currentProfileId,
        'is_typing': isTyping,
      },
    );
  }

  Future<void> dispose() async {
    _typingClearTimer?.cancel();
    if (_channel != null) {
      await client.removeChannel(_channel!);
    }
    await _controller.close();
  }
}
