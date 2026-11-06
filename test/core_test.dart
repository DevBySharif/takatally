import 'package:flutter_test/flutter_test.dart';
import 'package:taka_counter/core/formatters.dart';

void main() {
  group('Bangladeshi money formatting', () {
    test('uses lakh and crore grouping', () {
      expect(formatNumber(0), '0');
      expect(formatNumber(999), '999');
      expect(formatNumber(1000), '1,000');
      expect(formatNumber(193130), '1,93,130');
      expect(formatNumber(10000000), '1,00,00,000');
    });

    test('formats signed amounts', () {
      expect(formatMoney(193130), '৳1,93,130');
      expect(formatMoney(-2500, signed: true), '−৳2,500');
      expect(formatMoney(5000, signed: true), '+৳5,000');
    });

    test('converts to Bengali numerals', () {
      expect(bengaliNumerals('৳1,93,130'), '৳১,৯৩,১৩০');
    });
  });
}
