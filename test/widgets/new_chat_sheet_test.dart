import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/src/domain/models/profile.dart';
import 'package:guten_chat/src/domain/repositories/chat_repository.dart';
import 'package:guten_chat/src/presentation/theme/chat_theme.dart';
import 'package:guten_chat/src/presentation/widgets/chats/new_chat_sheet.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late _MockChatRepository repository;

  setUp(() {
    repository = _MockChatRepository();
  });

  const contacts = [
    ChatContact(profileId: 'p1', name: 'Alice Anders'),
    ChatContact(profileId: 'p2', name: 'Bob Berg'),
  ];

  Future<List<ChatContact>> lookup(String query) async {
    if (query.isEmpty) {
      return contacts;
    }
    return contacts
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> pumpSheet(
    WidgetTester tester, {
    ContactsLookup? contactsLookup,
    ValueChanged<String>? onCreated,
    VoidCallback? onNewCommunity,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGutenChatMaterialTheme(
          chatTheme: const GutenChatTheme().toChatTheme(Brightness.dark),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => NewChatSheet.show(
                  context,
                  repository: repository,
                  contactsLookup: contactsLookup ?? lookup,
                  onCreated: onCreated ?? (_) {},
                  onNewCommunity: onNewCommunity ?? () {},
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders New community row and initial contacts', (tester) async {
    await pumpSheet(tester);

    expect(find.text('New chat'), findsOneWidget);
    expect(find.text('New community'), findsOneWidget);
    expect(find.text('Alice Anders'), findsOneWidget);
    expect(find.text('Bob Berg'), findsOneWidget);
  });

  testWidgets('tapping a contact calls createDm and opens the conversation',
      (tester) async {
    when(() => repository.createDm('p1'))
        .thenAnswer((_) async => 'conv-1');
    String? createdConversationId;

    await pumpSheet(
      tester,
      onCreated: (id) => createdConversationId = id,
    );

    await tester.tap(find.text('Alice Anders'));
    await tester.pumpAndSettle();

    verify(() => repository.createDm('p1')).called(1);
    expect(createdConversationId, 'conv-1');
    // Sheet dismissed after creation.
    expect(find.text('New chat'), findsNothing);
  });

  testWidgets('search filters contacts after the debounce', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(find.byType(TextField), 'bob');
    // Before the 300 ms debounce fires the list is unchanged.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Alice Anders'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Alice Anders'), findsNothing);
    expect(find.text('Bob Berg'), findsOneWidget);
  });

  testWidgets('shows empty state when no contacts match', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('No contacts found'), findsOneWidget);
  });

  testWidgets('New community row dismisses the sheet and routes onward',
      (tester) async {
    var routed = false;

    await pumpSheet(tester, onNewCommunity: () => routed = true);

    await tester.tap(find.text('New community'));
    await tester.pumpAndSettle();

    expect(routed, isTrue);
    expect(find.text('New chat'), findsNothing);
    verifyNever(() => repository.createDm(any()));
  });
}
