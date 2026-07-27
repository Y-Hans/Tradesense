import 'package:flutter/foundation.dart';

@immutable
class VirtualWallet {
  final double balanceInr;
  final double lockedInr;
  final double initialBalanceInr;

  const VirtualWallet({
    required this.balanceInr,
    required this.lockedInr,
    this.initialBalanceInr = 100000.0,
  });

  factory VirtualWallet.initial() => const VirtualWallet(
        balanceInr: 100000.0,
        lockedInr: 0.0,
        initialBalanceInr: 100000.0,
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
        initialBalanceInr:
            (json['initial_balance_inr'] as num?)?.toDouble() ?? 100000.0,
      );
}
