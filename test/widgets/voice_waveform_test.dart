import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/src/presentation/widgets/voice_note_attachment_view.dart'
    show VoiceWaveform;

void main() {
  Future<void> pumpWave(
    WidgetTester tester, {
    required double progress,
    ValueChanged<double>? onSeek,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 256,
              child: VoiceWaveform(
                progress: progress,
                ink: const Color(0xFFFFFFFF),
                onSeek: onSeek,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders the 32 web-parity bars', (tester) async {
    await pumpWave(tester, progress: 0);
    expect(VoiceWaveform.barHeights.length, 32);
    expect(find.byType(DecoratedBox), findsNWidgets(32));
  });

  testWidgets('splits played vs unplayed ink at the progress fraction',
      (tester) async {
    await pumpWave(tester, progress: 0.5);
    final boxes = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((w) => (w.decoration as BoxDecoration).color)
        .toList();
    // Bars 0–15 played (full ink), 16–31 unplayed (26% ink).
    expect(boxes.take(16).every((c) => c!.a == 1.0), isTrue);
    expect(boxes.skip(16).every((c) => c!.a < 0.3), isTrue);
  });

  testWidgets('tap scrubs to the tapped fraction', (tester) async {
    double? seeked;
    await pumpWave(tester, progress: 0, onSeek: (f) => seeked = f);
    final rect = tester.getRect(find.byType(VoiceWaveform));
    await tester.tapAt(Offset(rect.left + rect.width * 0.75, rect.center.dy));
    await tester.pump();
    expect(seeked, isNotNull);
    expect(seeked!, closeTo(0.75, 0.05));
  });
}
