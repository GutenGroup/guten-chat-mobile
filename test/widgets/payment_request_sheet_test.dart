import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/src/presentation/cubit/conversation_cubit.dart';
import 'package:guten_chat/src/presentation/theme/chat_theme.dart';
import 'package:guten_chat/src/presentation/widgets/payment_request_sheet.dart';
import 'package:mocktail/mocktail.dart';

class _MockConversationCubit extends Mock implements ConversationCubit {}

void main() {
  late _MockConversationCubit cubit;

  setUp(() {
    cubit = _MockConversationCubit();
  });

  Widget buildSheet() {
    return MaterialApp(
      theme: buildGutenChatMaterialTheme(
        chatTheme: const GutenChatTheme().toChatTheme(Brightness.dark),
      ),
      home: Scaffold(
        body: PaymentRequestSheet(cubit: cubit),
      ),
    );
  }

  testWidgets('PaymentRequestSheet disables send when amount is zero',
      (tester) async {
    await tester.pumpWidget(buildSheet());

    final sendButton = find.widgetWithText(FilledButton, 'Send request');
    expect(tester.widget<FilledButton>(sendButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, '0');
    await tester.pump();

    expect(tester.widget<FilledButton>(sendButton).onPressed, isNull);
  });

  testWidgets('PaymentRequestSheet submits valid amount in cents',
      (tester) async {
    when(
      () => cubit.createPaymentRequest(
        amountCents: any(named: 'amountCents'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(buildSheet());

    await tester.enterText(find.byType(TextField).first, '12.50');
    await tester.pump();

    final sendButton = find.widgetWithText(FilledButton, 'Send request');
    expect(tester.widget<FilledButton>(sendButton).onPressed, isNotNull);

    await tester.tap(sendButton);
    await tester.pump();

    verify(
      () => cubit.createPaymentRequest(
        amountCents: 1250,
        note: null,
      ),
    ).called(1);
  });
}
