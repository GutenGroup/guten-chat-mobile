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
import 'chats/chats_screen.dart';
import 'chats/new_chat_sheet.dart';
import 'communities/communities_screen.dart';
import 'conversation_screen.dart';
import 'groups/group_icon_picker.dart';
import 'groups/new_group_sheet.dart';
import 'profile/profile_screen.dart';
import 'shell/liquid_glass_bottom_bar.dart';
import 'updates/updates_screen.dart';

/// Single public entrypoint widget for host apps.
class GutenChat extends StatefulWidget {
  const GutenChat({
    super.key,
    required this.supabase,
    required this.profileLookup,
    this.contactsLookup,
    this.features = const ChatFeatures(),
    this.theme = const GutenChatTheme(),
    this.brandMarks = const [],
    this.initialConversationId,
    this.initialTab = GutenChatTab.chats,
    this.repository,
    this.profileDisplayName = 'You',
    this.profileHandle = 'user',
    this.onUploadGroupIcon,
    this.onEditProfile,
    this.onJoinPaidCommunity,
    this.buildLabel,
  });

  final SupabaseClient supabase;
  final ProfileLookup profileLookup;

  /// Optional host-supplied contact directory. When provided, the Chats tab
  /// pencil opens a "New chat" sheet (contact search → DM, plus a
  /// "New community" entry). When null, the pencil opens the community sheet
  /// directly — today's behavior, so existing hosts are unaffected.
  final ContactsLookup? contactsLookup;
  final ChatFeatures features;
  final GutenChatTheme theme;
  final List<BrandReactionMark> brandMarks;
  final GutenChatTab initialTab;

  /// When set, opens directly into a conversation thread.
  final String? initialConversationId;

  /// Optional override for tests.
  final ChatRepository? repository;

  /// Profile tab display metadata supplied by the host app.
  final String profileDisplayName;
  final String profileHandle;
  final GroupIconUploadCallback? onUploadGroupIcon;
  final VoidCallback? onEditProfile;

  /// Host-provided checkout for paid communities. Return `true` when the user
  /// has joined (paid_status flips to `active` via the host webhook).
  final JoinPaidCommunityHandler? onJoinPaidCommunity;

  /// Optional build stamp (e.g. "b16 · chat 0.4.3") rendered as a tiny
  /// caption at the bottom of the Chats tab — mirrors the web app's version
  /// footer so testers can tell exactly which build feedback refers to.
  final String? buildLabel;

  @override
  State<GutenChat> createState() => _GutenChatState();
}

class _GutenChatState extends State<GutenChat> with WidgetsBindingObserver {
  late final ChatRepository _repository;
  late final ChatFeatures _features;
  late GutenChatAppearance _appearance;
  late GutenChatTab _selectedTab;
  String? _openConversationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _features = resolveFeatures(widget.features);
    _repository = widget.repository ??
        ChatRepositoryImpl(ChatRemoteDataSource(widget.supabase));
    _openConversationId = widget.initialConversationId;
    _appearance = widget.theme.appearance;
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _repository.dispose();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (_appearance == GutenChatAppearance.system) {
      setState(() {});
    }
  }

  void _openConversation(String conversationId) {
    setState(() => _openConversationId = conversationId);
  }

  void _closeConversation() {
    // Drop the keyboard before the tree swap so the inbox + bar never mount
    // mid-keyboard-dismiss (out-of-sync settle).
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _openConversationId = null);
  }

  void _onAppearanceChanged(GutenChatAppearance appearance) {
    setState(() => _appearance = appearance);
  }

  GutenChatTheme get _resolvedTheme =>
      widget.theme.copyWith(appearance: _appearance);

  Widget _wrapWithTheme({required Widget child}) {
    final brightness = _resolvedTheme.resolveBrightness(
      MediaQuery.platformBrightnessOf(context),
    );
    final chatTheme = _resolvedTheme.toChatTheme(brightness);

    return Theme(
      data: buildGutenChatMaterialTheme(chatTheme: chatTheme),
      child: child,
    );
  }

  void _showNewGroupSheet({bool isPaid = false}) {
    NewGroupSheet.show(
      context,
      repository: _repository,
      isPaid: isPaid,
      onUploadIcon: widget.onUploadGroupIcon,
      contactsLookup: widget.contactsLookup,
      onCreated: _openConversation,
    );
  }

  void _showNewChatSheet() {
    final contactsLookup = widget.contactsLookup;
    if (contactsLookup == null) {
      _showNewGroupSheet();
      return;
    }
    NewChatSheet.show(
      context,
      repository: _repository,
      contactsLookup: contactsLookup,
      onCreated: _openConversation,
      onNewCommunity: _showNewGroupSheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_openConversationId != null) {
      return _wrapWithTheme(
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
            repository: _repository,
            onBack: _closeConversation,
            onUploadGroupIcon: widget.onUploadGroupIcon,
            onJoinPaidCommunity: widget.onJoinPaidCommunity,
          ),
        ),
      );
    }

    final initials = widget.profileDisplayName.isNotEmpty
        ? widget.profileDisplayName[0].toUpperCase()
        : '?';

    return _wrapWithTheme(
      child: BlocProvider(
        create: (_) => InboxCubit(
          repository: _repository,
          profileLookup: widget.profileLookup,
        )..load(),
        child: Scaffold(
          // WhatsApp standard (Daniel 2026-07-03): the tab bar is LOCKED to
          // the physical screen bottom — the keyboard slides OVER it, it
          // never floats up. The body pads itself by the keyboard inset
          // instead, so list content (e.g. the Chats search field) stays
          // visible while the bar holds still under the keyboard.
          resizeToAvoidBottomInset: false,
          body: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: IndexedStack(
              index: _selectedTab.index,
              children: [
                const UpdatesScreen(),
                ChatsScreen(
                  repository: _repository,
                  onConversationTap: (c) => _openConversation(c.id),
                  onCreateGroup: _showNewChatSheet,
                  onUploadGroupIcon: widget.onUploadGroupIcon,
                  buildLabel: widget.buildLabel,
                ),
                CommunitiesScreen(
                  repository: _repository,
                  onCommunityTap: (c) => _openConversation(c.id),
                  onCreateCommunity: () => _showNewGroupSheet(isPaid: true),
                  onUploadGroupIcon: widget.onUploadGroupIcon,
                ),
                ProfileScreen(
                  displayName: widget.profileDisplayName,
                  handle: widget.profileHandle,
                  avatarInitials: initials,
                  appearance: _appearance,
                  onAppearanceChanged: _onAppearanceChanged,
                  onEditProfile: widget.onEditProfile,
                ),
              ],
            ),
          ),
          bottomNavigationBar: LiquidGlassBottomBar(
            selected: _selectedTab,
            profileInitials: initials,
            onSelected: (tab) => setState(() => _selectedTab = tab),
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
    this.theme = const GutenChatTheme(),
    this.brandMarks = const [],
    this.repository,
    this.title,
    this.onUploadGroupIcon,
    this.onJoinPaidCommunity,
  });

  final SupabaseClient supabase;
  final ProfileLookup profileLookup;
  final String conversationId;
  final ChatFeatures features;
  final GutenChatTheme theme;
  final List<BrandReactionMark> brandMarks;
  final ChatRepository? repository;
  final String? title;
  final GroupIconUploadCallback? onUploadGroupIcon;
  final JoinPaidCommunityHandler? onJoinPaidCommunity;

  @override
  Widget build(BuildContext context) {
    final resolvedFeatures = resolveFeatures(features);
    final chatRepository = repository ??
        ChatRepositoryImpl(ChatRemoteDataSource(supabase));
    final brightness = theme.resolveBrightness(
      MediaQuery.platformBrightnessOf(context),
    );
    final chatTheme = theme.toChatTheme(brightness);

    return Theme(
      data: buildGutenChatMaterialTheme(chatTheme: chatTheme),
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
          repository: chatRepository,
          title: title,
          onUploadGroupIcon: onUploadGroupIcon,
          onJoinPaidCommunity: onJoinPaidCommunity,
        ),
      ),
    );
  }
}
