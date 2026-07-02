import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/src/presentation/widgets/jump_to_latest_pill.dart';

void main() {
  testWidgets('JumpToLatestPill shows count and handles tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              JumpToLatestPill(
                count: 3,
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('3 new messages'), findsOneWidget);
    await tester.tap(find.text('3 new messages'));
    expect(tapped, isTrue);
  });

  testWidgets('JumpToLatestPill hidden when count is zero', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JumpToLatestPill(count: 0, onTap: _noop),
        ),
      ),
    );

    expect(find.byType(Text), findsNothing);
  });
}

void _noop() {}
