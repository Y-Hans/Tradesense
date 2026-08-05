import 'package:flutter/material.dart';
import '../../tokens/spacing.dart';
import 'evidence_chip.dart';

/// A row showing the data provenance (e.g., specific trades) for an AI insight.
///
/// Example usage:
/// ```dart
/// ProvenanceRow(
///   trades: ['NVDA', 'SPY call spread', 'AAPL short cover'],
/// )
/// ```
class ProvenanceRow extends StatelessWidget {
  final List<String> trades;
  final Function(String)? onTradeTap;

  const ProvenanceRow({
    super.key,
    required this.trades,
    this.onTradeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: trades.map((trade) {
        return EvidenceChip(
          label: trade,
          onTap: onTradeTap != null ? () => onTradeTap!(trade) : null,
        );
      }).toList(),
    );
  }
}
