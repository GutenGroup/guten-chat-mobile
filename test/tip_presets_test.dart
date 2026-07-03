import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/src/domain/models/tip_presets.dart';

void main() {
  group('TipPresets', () {
    test('offers exactly four preset amounts in order', () {
      expect(TipPresets.amountCents, [100, 300, 500, 1000]);
      expect(TipPresets.formatAmount(100), '\$1');
      expect(TipPresets.formatAmount(300), '\$3');
      expect(TipPresets.formatAmount(500), '\$5');
      expect(TipPresets.formatAmount(1000), '\$10');
    });
  });
}
