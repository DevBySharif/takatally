import 'package:intl/intl.dart';

String indianDigits(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  if (digits.length <= 3) return '${negative ? '-' : ''}$digits';
  final lastThree = digits.substring(digits.length - 3);
  final rest = digits.substring(0, digits.length - 3);
  final buffer = StringBuffer();
  for (var i = 0; i < rest.length; i++) {
    final remaining = rest.length - i;
    buffer.write(rest[i]);
    if (remaining > 1 && remaining.isOdd) buffer.write(',');
  }
  return '${negative ? '-' : ''}$buffer,$lastThree';
}

String formatNumber(int value) => indianDigits(value);

String formatMoney(
  int value, {
  bool symbol = true,
  bool signed = false,
  String symbolText = '৳',
}) {
  final sign = signed
      ? value > 0
          ? '+'
          : value < 0
              ? '−'
              : ''
      : value < 0
          ? '−'
          : '';
  final amount = indianDigits(value.abs());
  return '$sign${symbol ? symbolText : ''}$amount';
}

String formatCompact(int value) {
  final abs = value.abs();
  final sign = value < 0 ? '−' : '';
  if (abs >= 10000000) {
    final v = abs / 10000000;
    return '$sign৳${_trim(v)}Cr';
  }
  if (abs >= 100000) {
    final v = abs / 100000;
    return '$sign৳${_trim(v)}L';
  }
  if (abs >= 1000) {
    final v = abs / 1000;
    return '$sign৳${_trim(v)}K';
  }
  return '$sign৳$abs';
}

String _trim(double value) {
  final text = value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

String bengaliNumerals(String input) {
  const digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  final buffer = StringBuffer();
  for (final char in input.split('')) {
    final index = int.tryParse(char);
    buffer.write(index == null ? char : digits[index]);
  }
  return buffer.toString();
}

String formatDateHeader(DateTime date) => DateFormat('EEEE, dd/MM/yyyy').format(date);

String formatDateShort(DateTime date) => DateFormat('dd MMM yyyy').format(date);

String formatDateGroup(DateTime date) => DateFormat('MMMM yyyy').format(date);

String formatTime(DateTime date) => DateFormat('h:mm a').format(date);

String formatDateTime(DateTime date) =>
    '${formatDateShort(date)} · ${formatTime(date)}';

String relativeDay(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return formatDateShort(date);
}

String greetingFor(DateTime date) {
  if (date.hour < 12) return 'Good morning';
  if (date.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String shortCount(int count) => count == 1 ? '1 entry' : '$count entries';

String plural(int count, String singular, [String? pluralText]) =>
    count == 1 ? singular : (pluralText ?? '${singular}s');
