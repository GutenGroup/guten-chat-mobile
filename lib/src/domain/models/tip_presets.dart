/// Default tip ladder when the host does not supply custom amounts.
abstract final class TipPresets {
  static const symbol = '♥';

  static const currency = 'USD';

  static const amountCents = <int>[100, 300, 500, 1000];

  static String formatAmount(int amountCents, {String currencyCode = currency}) {
    final dollars = amountCents / 100;
    if (amountCents % 100 == 0) {
      return '\$${dollars.toInt()}';
    }
    return '\$${dollars.toStringAsFixed(2)}';
  }
}
