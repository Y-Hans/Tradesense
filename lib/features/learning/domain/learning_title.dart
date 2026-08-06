import 'learning_constants.dart';

enum LearningTitleType {
  cryptoRookie,
  marketExplorer,
  riskAwareTrader,
  disciplinedTrader,
  cryptoMentor,
}

class LearningTitle {
  final LearningTitleType type;
  final String title;
  final String description;
  final int minXp;

  const LearningTitle({
    required this.type,
    required this.title,
    required this.description,
    required this.minXp,
  });

  static const List<LearningTitle> titles = [
    LearningTitle(
      type: LearningTitleType.cryptoRookie,
      title: 'Crypto Rookie',
      description: 'Starting your financial literacy journey.',
      minXp: LearningConstants.xpTitleCryptoRookie,
    ),
    LearningTitle(
      type: LearningTitleType.marketExplorer,
      title: 'Market Explorer',
      description: 'Exploring market concepts and data.',
      minXp: LearningConstants.xpTitleMarketExplorer,
    ),
    LearningTitle(
      type: LearningTitleType.riskAwareTrader,
      title: 'Risk-Aware Trader',
      description: 'Understanding risk management and stop-loss.',
      minXp: LearningConstants.xpTitleRiskAwareTrader,
    ),
    LearningTitle(
      type: LearningTitleType.disciplinedTrader,
      title: 'Disciplined Trader',
      description: 'Consistently applying disciplined trading habits.',
      minXp: LearningConstants.xpTitleDisciplinedTrader,
    ),
    LearningTitle(
      type: LearningTitleType.cryptoMentor,
      title: 'Crypto Mentor',
      description: 'Mastered core educational concepts & guides others.',
      minXp: LearningConstants.xpTitleCryptoMentor,
    ),
  ];

  /// Resolves the user's title based on total earned XP.
  static LearningTitle fromXp(int xp) {
    final sanitizedXp = xp < 0 ? 0 : xp;
    for (final t in titles.reversed) {
      if (sanitizedXp >= t.minXp) {
        return t;
      }
    }
    return titles.first;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningTitle &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          minXp == other.minXp;

  @override
  int get hashCode => type.hashCode ^ minXp.hashCode;

  @override
  String toString() => 'LearningTitle(title: $title, minXp: $minXp)';
}
