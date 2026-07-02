import 'package:flutter_test/flutter_test.dart';
import 'package:guten_chat/guten_chat.dart';

void main() {
  group('resolveFeatures', () {
    test('disables brand reactions when reactions are off', () {
      const input = ChatFeatures(reactions: false, brandReactions: true);
      final resolved = resolveFeatures(input);
      expect(resolved.reactions, isFalse);
      expect(resolved.brandReactions, isFalse);
    });

    test('keeps independent flags when valid', () {
      const input = ChatFeatures(
        reactions: true,
        brandReactions: true,
        tipping: true,
        paymentRequests: false,
      );
      final resolved = resolveFeatures(input);
      expect(resolved.reactions, isTrue);
      expect(resolved.brandReactions, isTrue);
      expect(resolved.tipping, isTrue);
      expect(resolved.paymentRequests, isFalse);
    });

    test('ChatFeatures.resolve applies defaults', () {
      final features = ChatFeatures.resolve(tipping: true);
      expect(features.reactions, isTrue);
      expect(features.tipping, isTrue);
      expect(features.paidGroups, isFalse);
    });
  });
}
