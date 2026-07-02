import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

import '../../domain/models/message.dart';

/// Builds UI list items with day dividers and consecutive-sender grouping.
List<MessageListItem> buildMessageListItems(
  List<Message> messages, {
  required bool isGroup,
}) {
  if (messages.isEmpty) {
    return const [];
  }

  final sorted = List<Message>.from(messages)
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  final items = <MessageListItem>[];
  DateTime? currentDay;
  String? previousSenderId;

  for (final message in sorted) {
    final day = DateTime.utc(
      message.createdAt.year,
      message.createdAt.month,
      message.createdAt.day,
    );

    if (currentDay == null || !_isSameDay(currentDay, day)) {
      items.add(DayDividerItem(day));
      currentDay = day;
      previousSenderId = null;
    }

    final sameSender = previousSenderId == message.senderProfileId;
    items.add(
      MessageItem(
        message: message,
        isGroupedWithPrevious: sameSender && !message.isSystem,
        showAvatar: isGroup && !sameSender,
      ),
    );
    previousSenderId = message.senderProfileId;
  }

  return items;
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatDayDivider(DateTime day) {
  final now = DateTime.now().toUtc();
  final today = DateTime.utc(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final target = DateTime.utc(day.year, day.month, day.day);

  if (target == today) {
    return 'Today';
  }
  if (target == yesterday) {
    return 'Yesterday';
  }
  return DateFormat.yMMMMd().format(day.toLocal());
}

/// Merges optimistic messages with server messages, de-duping by id and
/// client temp id (mirrors web optimistic-echo handling).
List<Message> mergeMessages({
  required List<Message> serverMessages,
  required List<Message> optimisticMessages,
}) {
  final byId = {for (final m in serverMessages) m.id: m};
  final byTempId = {
    for (final m in serverMessages)
      if (m.clientTempId != null) m.clientTempId!: m,
  };

  final merged = <Message>[...serverMessages];

  for (final optimistic in optimisticMessages) {
    if (byId.containsKey(optimistic.id)) {
      continue;
    }
    if (optimistic.clientTempId != null &&
        byTempId.containsKey(optimistic.clientTempId)) {
      continue;
    }
    merged.add(optimistic);
  }

  merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return merged;
}

Message createOptimisticMessage({
  required String tempId,
  required String conversationId,
  required String senderProfileId,
  required String body,
  String? replyToMessageId,
  String? replyPreview,
}) {
  return Message(
    id: tempId,
    conversationId: conversationId,
    senderProfileId: senderProfileId,
    body: body,
    createdAt: DateTime.now().toUtc(),
    replyToMessageId: replyToMessageId,
    replyPreview: replyPreview,
    status: MessageStatus.sending,
    clientTempId: tempId,
  );
}

sealed class MessageListItem {
  const MessageListItem();
}

class DayDividerItem extends MessageListItem {
  const DayDividerItem(this.day);
  final DateTime day;
}

class MessageItem extends MessageListItem {
  const MessageItem({
    required this.message,
    required this.isGroupedWithPrevious,
    required this.showAvatar,
  });

  final Message message;
  final bool isGroupedWithPrevious;
  final bool showAvatar;
}

extension MessageListItemX on List<MessageListItem> {
  Message? get lastMessage => map((item) {
        if (item is MessageItem) {
          return item.message;
        }
        return null;
      }).whereType<Message>().lastOrNull;
}
