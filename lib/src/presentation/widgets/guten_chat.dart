import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/models/chat_features.dart';
import '../../domain/models/profile.dart';
import '../../domain/repositories/chat_repository.dart';
import '../cubit/conversation_cubit.dart';
import '../cubit/inbox_cubit.dart';
import '../theme/chat_theme.dart';
import 'conversation_screen.dart';
import 'inbox_screen.dart';

/// Single public entrypoint widget for host apps.
class GutenChat extends StatefulWidget {
  const GutenChat({
    super.key,
    required this.supabase,
    required this.profileLookup,
    this.features = const ChatFeatures(),
    this.theme,
    this.brandMarks = const [],
    this.initialConversationId,
    this.repository,
  });

  final SupabaseClient supabase;
  final ProfileLookup profileLookup;
  final ChatFeatures features;
  final ChatTheme? theme;
  final List<BrandReactionMark> brandMarks;

  /// When set, opens directly into a conversation thread.
  final String? initialConversationId;

  /// Optional override for tests.
  final ChatRepository? repository;

  @override
  State<GutenChat> createState() => _GutenChatState();
}

class _GutenChatState extends State<GutenChat> {
  late final ChatRepository _repository;
  late final ChatFeatures _features;
  String? _openConversationId;

  @override
  void initState() {
    super.initState();
    _features = resolveFeatures(widget.features);
    _repository = widget.repository ??
        ChatRepositoryImpl(ChatRemoteDataSource(widget.supabase));
    _openConversationId = widget.initialConversationId;
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  void _openConversation(String conversationId) {
    setState(() => _openConversationId = conversationId);
  }

  void _closeConversation() {
    setState(() => _openConversationId = null);
  }

  @override
  Widget build(BuildContext context) {
    final chatTheme = widget.theme ?? const ChatTheme();

    if (_openConversationId != null) {
      return Theme(
        data: Theme.of(context).copyWith(
          extensions: [chatTheme],
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: chatTheme.primaryColor,
              ),
        ),
        child: BlocProvider(
          create: (_) => ConversationCubit(
            conversationId: _openConversationId!,
            repository: _repository,
            profileLookup: widget.profileLookup,
            features: _features,
          )..load(),
        child: ConversationScreen(
          conversationId: _openConversationId!,
          features: _features,
          brandMarks: widget.brandMarks,
          title: null,
          onBack: _closeConversation,
        ),
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [chatTheme],
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: chatTheme.primaryColor,
            ),
      ),
      child: BlocProvider(
        create: (_) => InboxCubit(
          repository: _repository,
          profileLookup: widget.profileLookup,
        )..load(),
        child: Scaffold(
          appBar: AppBar(title: const Text('Messages')),
          body: InboxScreen(
            onConversationTap: (conversation) =>
                _openConversation(conversation.id),
          ),
        ),
      ),
    );
  }
}

/// Host apps can push a conversation route using this helper.
class GutenChatConversationRoute extends StatelessWidget {
  const GutenChatConversationRoute({
    super.key,
    required this.supabase,
    required this.profileLookup,
    required this.conversationId,
    this.features = const ChatFeatures(),
    this.theme,
    this.brandMarks = const [],
    this.repository,
    this.title,
  });

  final SupabaseClient supabase;
  final ProfileLookup profileLookup;
  final String conversationId;
  final ChatFeatures features;
  final ChatTheme? theme;
  final List<BrandReactionMark> brandMarks;
  final ChatRepository? repository;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final resolvedFeatures = resolveFeatures(features);
    final chatTheme = theme ?? const ChatTheme();
    final chatRepository = repository ??
        ChatRepositoryImpl(ChatRemoteDataSource(supabase));

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [chatTheme],
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: chatTheme.primaryColor,
            ),
      ),
      child: BlocProvider(
        create: (_) => ConversationCubit(
          conversationId: conversationId,
          repository: chatRepository,
          profileLookup: profileLookup,
          features: resolvedFeatures,
        )..load(),
        child: ConversationScreen(
          conversationId: conversationId,
          features: resolvedFeatures,
          brandMarks: brandMarks,
          title: title,
        ),
      ),
    );
  }
}
