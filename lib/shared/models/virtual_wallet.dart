import 'package:flutter/foundation.dart';

@immutable
class VirtualWallet {
  static const double startingBalanceInr = 10000000.0;

  final double balanceInr;
  final double lockedInr;
  final double initialBalanceInr;

  const VirtualWallet({
    required this.balanceInr,
    required this.lockedInr,
    this.initialBalanceInr = startingBalanceInr,
  });

  factory VirtualWallet.initial() => const VirtualWallet(
        balanceInr: startingBalanceInr,
        lockedInr: 0.0,
        initialBalanceInr: startingBalanceInr,
      );

  double get availableBalanceInr => balanceInr - lockedInr;

  VirtualWallet copyWith({
    double? balanceInr,
    double? lockedInr,
    double? initialBalanceInr,
  }) {
    return VirtualWallet(
      balanceInr: balanceInr ?? this.balanceInr,
      lockedInr: lockedInr ?? this.lockedInr,
      initialBalanceInr: initialBalanceInr ?? this.initialBalanceInr,
    );
  }

  Map<String, dynamic> toJson() => {
        'balance_inr': balanceInr,
        'locked_inr': lockedInr,
        'initial_balance_inr': initialBalanceInr,
      };

  factory VirtualWallet.fromJson(Map<String, dynamic> json) => VirtualWallet(
        balanceInr: (json['balance_inr'] as num).toDouble(),
        lockedInr: (json['locked_inr'] as num).toDouble(),
        initialBalanceInr: (json['initial_balance_inr'] as num?)?.toDouble() ??
            startingBalanceInr,
      );
}
