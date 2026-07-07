import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/guten_chat.dart';
import 'package:guten_chat/src/presentation/widgets/message_bubble.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

/// Renders the REAL GutenChat conversation path with Fysigo's exact theme
/// (teal #04AA72, forced dark) and asserts the painted bubble colors — the
/// on-device complaint is "DLS not applied / black and white".
void main() {
  const teal = Color(0xFF04AA72);
  const fysigoTheme = GutenChatTheme(
    accentColor: teal,
    appearance: GutenChatAppearance.dark,
  );

  final ownMessage = Message(
    id: 'm-own',
    conversationId: 'c1',
    senderProfileId: 'me',
    body: 'my own message',
    createdAt: DateTime.utc(2026, 7, 6, 12),
  );
  final otherMessage = Message(
    id: 'm-other',
    conversationId: 'c1',
    senderProfileId: 'p2',
    body: 'their message',
    createdAt: DateTime.utc(2026, 7, 6, 12, 1),
  );

  Future<ChatProfile> lookup(String id) async =>
      ChatProfile(name: id == 'me' ? 'Me' : 'Other');

  Color? bubbleColorOf(WidgetTester tester, String text) {
    final content = find.ancestor(
      of: find.text(text),
      matching: find.byType(MessageBubbleContent),
    );
    expect(content, findsOneWidget,
        reason: 'bubble content for "$text" should render');
    final containers = tester.widgetList<Container>(
      find.descendant(of: content, matching: find.byType(Container)),
    );
    for (final c in containers) {
      final deco = c.decoration;
      if (deco is BoxDecoration && deco.color != null) {
        return deco.color;
      }
    }
    return null;
  }

  testWidgets(
      'GutenChat conversation paints own bubble teal, incoming neutral '
      '(fysigo theme, real widget tree)', (tester) async {
    final repository = _MockChatRepository();
    final supabase = _MockSupabaseClient();

    final conversation = Conversation(
      id: 'c1',
      type: ConversationType.dm,
      title: 'Probe',
      createdAt: DateTime.utc(2026, 7, 6),
      updatedAt: DateTime.utc(2026, 7, 6),
    );

    when(() => repository.getCurrentProfileId())
        .thenAnswer((_) async => 'me');
    when(() => repository.fetchConversation('c1'))
        .thenAnswer((_) async => conversation);
    when(() => repository.fetchMessages('c1', limit: any(named: 'limit')))
        .thenAnswer((_) async => [ownMessage, otherMessage]);
    when(() => repository.fetchParticipants('c1'))
        .thenAnswer((_) async => []);
    when(() => repository.watchConversation('c1'))
        .thenAnswer((_) => const Stream.empty());
    when(() => repository.markRead('c1', messageId: any(named: 'messageId')))
        .thenAnswer((_) async {});
    when(() => repository.setTyping('c1', any()))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: GutenChat(
          supabase: supabase,
          profileLookup: lookup,
          repository: repository,
          theme: fysigoTheme,
          initialConversationId: 'c1',
          profileDisplayName: 'Me',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('my own message'), findsOneWidget);

    final ownColor = bubbleColorOf(tester, 'my own message');
    final otherColor = bubbleColorOf(tester, 'their message');

    // The v0.5.0 design: outgoing = host accent, incoming = neutral raised.
    expect(ownColor, teal,
        reason: 'own bubble must carry the Fysigo DLS accent');
    expect(otherColor, const Color(0xFF1F1F22),
        reason: 'incoming bubble must be the token neutral');
  });
}
