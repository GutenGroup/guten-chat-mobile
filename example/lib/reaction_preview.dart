// Standalone offline preview for the redesigned reaction chips.
// Renders the REAL MessageBubble widget with seeded reactions (no backend) so
// the chip design can be screenshotted on a simulator. Not shipped.
import 'package:flutter/material.dart';
import 'package:guten_chat/guten_chat.dart';
// MessageBubble is package-internal; import it directly for the preview.
// ignore: implementation_imports
import 'package:guten_chat/src/presentation/widgets/message_bubble.dart';

void main() => runApp(const ReactionPreviewApp());

/// Satisfies ChatRepository via noSuchMethod — the seeded messages carry no
/// attachments, so none of its methods are ever invoked by MessageBubble.
class _FakeRepo implements ChatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final _repo = _FakeRepo();
final _now = DateTime(2026, 7, 4, 9, 24);

Reaction _r(String messageId, String profileId, String value) => Reaction(
      messageId: messageId,
      profileId: profileId,
      value: value,
      kind: ReactionKind.emoji,
      createdAt: _now,
    );

class ReactionPreviewApp extends StatelessWidget {
  const ReactionPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    final chatTheme = const GutenChatTheme(accentColor: Color(0xFF04AA72))
        .toChatTheme(Brightness.dark);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: chatTheme.backgroundColor,
        extensions: <ThemeExtension<dynamic>>[chatTheme],
      ),
      home: const _PreviewScreen(),
    );
  }
}

class _PreviewScreen extends StatelessWidget {
  const _PreviewScreen();

  Widget _bubble({
    required String id,
    required bool isOwn,
    required String senderName,
    required String body,
    required List<Reaction> reactions,
  }) {
    final message = Message(
      id: id,
      conversationId: 'c1',
      senderProfileId: isOwn ? 'me' : id,
      body: body,
      createdAt: _now,
      reactions: reactions,
    );
    return MessageBubble(
      message: message,
      isOwn: isOwn,
      showAvatar: !isOwn,
      isGroupedWithPrevious: false,
      profile: ChatProfile(name: senderName),
      features: ChatFeatures.resolve(reactions: true),
      isGroup: true,
      seenCount: 0,
      onReply: () {},
      onToggleReaction: (_, __) {},
      brandMarks: const [],
      repository: _repo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final caption = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF6B6B6B),
          letterSpacing: 0.6,
        );
    Widget cap(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 2),
          child: Text(t.toUpperCase(), style: caption),
        );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            cap('1 · incoming, single reaction (round chip)'),
            _bubble(
              id: 'm1',
              isOwn: false,
              senderName: 'Tony',
              body: 'Shipped the marketing site 🚀',
              reactions: [_r('m1', 'x', '❤️')],
            ),
            cap('2 · outgoing, count + mine (accent)'),
            _bubble(
              id: 'm2',
              isOwn: true,
              senderName: 'Daniel',
              body: "Nice — let's push it live.",
              reactions: [_r('m2', 'me', '👍'), _r('m2', 'a', '👍'), _r('m2', 'b', '👍')],
            ),
            cap('3 · incoming, multi-line + several (mine on dark)'),
            _bubble(
              id: 'm3',
              isOwn: false,
              senderName: 'Gislaine',
              body:
                  'Numbers for Q3 are in. MRR up 14% and churn is finally under 2%. Full deck lands tomorrow AM.',
              reactions: [
                _r('m3', '', '❤️'), // profileId '' → "mine" on an incoming msg
                _r('m3', 'a', '🎉'), _r('m3', 'b', '🎉'),
                _r('m3', 'c', '🔥'),
              ],
            ),
            cap('4 · outgoing, many reactions incl. mine (wrap)'),
            _bubble(
              id: 'm4',
              isOwn: true,
              senderName: 'Daniel',
              body: 'Board approved the raise 🎯',
              reactions: [
                _r('m4', 'me', '🎉'), _r('m4', 'a', '🎉'), _r('m4', 'b', '🎉'),
                _r('m4', 'c', '🎉'), _r('m4', 'd', '🎉'),
                _r('m4', 'e', '❤️'), _r('m4', 'f', '❤️'), _r('m4', 'g', '❤️'),
                _r('m4', 'h', '❤️'),
                _r('m4', 'i', '👏'), _r('m4', 'j', '👏'),
                _r('m4', 'k', '🚀'),
              ],
            ),
            cap('5 · reaction never covers the next message'),
            _bubble(
              id: 'm5',
              isOwn: false,
              senderName: 'Tony',
              body: 'Sounds good.',
              reactions: [_r('m5', 'x', '👍')],
            ),
            _bubble(
              id: 'm6',
              isOwn: true,
              senderName: 'Daniel',
              body: 'Talk tomorrow.',
              reactions: const [],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
