import 'package:flutter/material.dart';

import '../core/formatters.dart';

enum EntryKind { counted, credit, debit }

extension EntryKindX on EntryKind {
  String get storageName => name;

  String get label => switch (this) {
    EntryKind.counted => 'Cash',
    EntryKind.credit => 'Credit',
    EntryKind.debit => 'Debit',
  };

  String get heading => switch (this) {
    EntryKind.counted => 'Counted cash',
    EntryKind.credit => 'Money in',
    EntryKind.debit => 'Money out',
  };

  static EntryKind fromStorage(String? value) {
    return EntryKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => EntryKind.counted,
    );
  }

  IconData get icon => switch (this) {
    EntryKind.counted => Icons.payments_outlined,
    EntryKind.credit => Icons.south_west_rounded,
    EntryKind.debit => Icons.north_east_rounded,
  };
}

@immutable
class TallyEntry {
  const TallyEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.quantity,
    required this.note,
    required this.createdAt,
    this.noteCounts = const {},
    this.coinCounts = const {},
  });

  final String id;
  final EntryKind kind;
  final int amount;
  final int quantity;
  final String note;
  final DateTime createdAt;

  /// Pieces per banknote denomination, e.g. `{1000: 3, 500: 2}`. Only entries
  /// that came from the note counter carry this.
  final Map<int, int> noteCounts;

  /// Pieces per coin denomination, e.g. `{5: 8}`.
  final Map<int, int> coinCounts;

  bool get hasBreakdown => noteCounts.isNotEmpty || coinCounts.isNotEmpty;

  int get pieceCount =>
      noteCounts.values.fold(0, (sum, qty) => sum + qty) +
      coinCounts.values.fold(0, (sum, qty) => sum + qty);

  int get breakdownTotal {
    var total = 0;
    noteCounts.forEach((value, qty) => total += value * qty);
    coinCounts.forEach((value, qty) => total += value * qty);
    return total;
  }

  /// Notes first (largest first), then coins, ready to render.
  List<({int value, int quantity, bool coin})> get breakdownItems {
    final notes = noteCounts.keys.toList()..sort((a, b) => b.compareTo(a));
    final coins = coinCounts.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final value in notes)
        (value: value, quantity: noteCounts[value]!, coin: false),
      for (final value in coins)
        (value: value, quantity: coinCounts[value]!, coin: true),
    ];
  }

  /// The complete one-line breakdown, e.g. `৳1,000 × 3 · ৳500 × 2 · ৳5 coin × 5`.
  String get breakdownLabel {
    final items = breakdownItems;
    return items
        .map(
          (item) =>
              '৳${formatNumber(item.value)}${item.coin ? ' coin' : ''} × ${item.quantity}',
        )
        .join(' · ');
  }

  /// A short one-liner such as `৳1,000 × 3 · ৳500 × 2 · +3 more`.
  String get breakdownPreview {
    final items = breakdownItems;
    if (items.isEmpty) return '';
    final shown = items
        .take(2)
        .map(
          (item) =>
              '৳${formatNumber(item.value)}${item.coin ? ' coin' : ''} × ${item.quantity}',
        );
    final rest = items.length - 2;
    return rest > 0 ? '${shown.join(' · ')} · +$rest more' : shown.join(' · ');
  }

  int get value => amount * quantity;

  int get signedValue => kind == EntryKind.debit ? -value : value;

  String get displayTitle {
    if (note.trim().isNotEmpty) return note.trim();
    if (hasBreakdown) return 'Notes & coins';
    return switch (kind) {
      EntryKind.counted => '৳${formatNumber(amount)} counted',
      EntryKind.credit => 'Credit added',
      EntryKind.debit => 'Debit added',
    };
  }

  TallyEntry copyWith({
    String? id,
    EntryKind? kind,
    int? amount,
    int? quantity,
    String? note,
    DateTime? createdAt,
    Map<int, int>? noteCounts,
    Map<int, int>? coinCounts,
  }) {
    return TallyEntry(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      noteCounts: noteCounts ?? this.noteCounts,
      coinCounts: coinCounts ?? this.coinCounts,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.storageName,
    'amount': amount,
    'quantity': quantity,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    if (noteCounts.isNotEmpty)
      'noteCounts': noteCounts.map(
        (value, qty) => MapEntry(value.toString(), qty),
      ),
    if (coinCounts.isNotEmpty)
      'coinCounts': coinCounts.map(
        (value, qty) => MapEntry(value.toString(), qty),
      ),
  };

  factory TallyEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final note = json['note'];
    final amount = (json['amount'] as num?)?.toInt() ?? 0;
    final quantity = (json['quantity'] as num?)?.toInt() ?? 1;
    return TallyEntry(
      id: id is String && id.isNotEmpty
          ? id
          : DateTime.now().microsecondsSinceEpoch.toString(),
      kind: EntryKindX.fromStorage(json['kind'] as String?),
      amount: amount.clamp(0, 999999999),
      quantity: quantity.clamp(1, 9999),
      note: note is String ? note : '',
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      noteCounts: _countsFrom(json['noteCounts']),
      coinCounts: _countsFrom(json['coinCounts']),
    );
  }

  static Map<int, int> _countsFrom(dynamic raw) {
    if (raw is! Map) return const {};
    final counts = <int, int>{};
    raw.forEach((key, value) {
      final denomination = int.tryParse('$key');
      final quantity = value is num
          ? value.toInt()
          : int.tryParse('$value') ?? 0;
      if (denomination != null &&
          denomination > 0 &&
          denomination <= 100000 &&
          quantity > 0) {
        counts[denomination] = quantity.clamp(1, 999999);
      }
    });
    return counts;
  }
}

@immutable
class TallySession {
  const TallySession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.entries,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TallyEntry> entries;

  int get total => entries.fold(0, (sum, entry) => sum + entry.signedValue);

  int get totalIn => entries
      .where((entry) => entry.signedValue > 0)
      .fold(0, (sum, entry) => sum + entry.signedValue);

  int get totalOut => entries
      .where((entry) => entry.signedValue < 0)
      .fold(0, (sum, entry) => sum + entry.signedValue.abs());

  int get cashTotal => entries
      .where((entry) => entry.kind == EntryKind.counted)
      .fold(0, (sum, entry) => sum + entry.signedValue);

  int get entryCount => entries.length;

  int get noteCount => entries
      .where((entry) => entry.kind == EntryKind.counted)
      .fold(
        0,
        (sum, entry) =>
            sum + (entry.hasBreakdown ? entry.pieceCount : entry.quantity),
      );

  bool get isEmpty => entries.isEmpty;

  TallySession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TallyEntry>? entries,
  }) {
    return TallySession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'entries': entries.map((entry) => entry.toJson()).toList(),
  };

  factory TallySession.fromJson(Map<String, dynamic> json) {
    final rawEntries = (json['entries'] as List<dynamic>?) ?? const [];
    return TallySession(
      id:
          (json['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: (json['title'] as String?) ?? 'Cash count',
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
      entries: rawEntries
          .whereType<Map<String, dynamic>>()
          .map(TallyEntry.fromJson)
          .toList(),
    );
  }
}

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.haptics = true,
    this.confirmDeletes = true,
  });

  final ThemeMode themeMode;
  final bool haptics;
  final bool confirmDeletes;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? haptics,
    bool? confirmDeletes,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      haptics: haptics ?? this.haptics,
      confirmDeletes: confirmDeletes ?? this.confirmDeletes,
    );
  }
}
