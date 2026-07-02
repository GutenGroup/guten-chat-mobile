import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/chat_features.dart';
import '../cubit/conversation_cubit.dart';
import 'chat_composer.dart';
import 'message_list_view.dart';

class ConversationScreen extends StatelessWidget {
  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.features,
    this.brandMarks = const [],
    this.title,
    this.onBack,
  });

  final String conversationId;
  final ChatFeatures features;
  final List<BrandReactionMark> brandMarks;
  final String? title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationCubit, ConversationState>(
      builder: (context, state) {
        final resolvedTitle =
            title ?? state.conversation?.title ?? 'Conversation';

        return Scaffold(
          appBar: AppBar(
            leading: onBack != null
                ? BackButton(onPressed: onBack)
                : null,
            title: Text(resolvedTitle),
            actions: [
              if (features.presence && state.onlineProfileIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Text(
                      '${state.onlineProfileIds.length} online',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: MessageListView(
                  features: features,
                  brandMarks: brandMarks,
                ),
              ),
              ChatComposer(
                features: features,
                brandMarks: brandMarks,
                replyToMessage: state.replyToMessage,
                onClearReply: () =>
                    context.read<ConversationCubit>().setReplyTo(null),
                onSend: (text) =>
                    context.read<ConversationCubit>().sendMessage(text),
                onTypingChanged: (isTyping) => context
                    .read<ConversationCubit>()
                    .notifyTyping(isTyping),
              ),
            ],
          ),
        );
      },
    );
  }
}
