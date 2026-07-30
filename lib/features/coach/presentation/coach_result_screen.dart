import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/models/trade.dart';
import '../../../shared/widgets/offline_state_widget.dart';
import '../../../shared/widgets/trade_card.dart';
import '../../intelligence/domain/discipline_reason_code_evaluator.dart';
import '../../intelligence/domain/risk_reason_code_evaluator.dart';
import '../domain/coach_context_builder.dart';
import '../domain/coach_result.dart';
import '../providers/coach_cache_providers.dart';

export '../providers/coach_cache_providers.dart'
    show aiProviderOverrideProvider;

/// Family provider driving the Coach pipeline flow:
/// Trade -> CoachContextBuilder -> CoachOrchestrator -> CoachResult
final coachResultProvider =
    FutureProvider.family<CoachResult?, String>((ref, tradeId) async {
  final tradingRepo = ref.watch(tradingRepositoryProvider);
  final history = await tradingRepo.getTradeHistory();

  Trade? trade;
  for (final t in history) {
    if (t.id == tradeId) {
      trade = t;
      break;
    }
  }

  if (trade == null) return null;

  final portfolio = await ref.watch(portfolioProvider.future);

  final hasStopLoss =
      trade.stopLossPriceInr != null || trade.type == OrderType.stopLoss;

  final riskResult = RiskReasonCodeEvaluator.analyze(
    portfolio: portfolio,
    proposedTradeSizeInr: trade.totalAmountInr,
    hasStopLoss: hasStopLoss,
    assetVolatility: 3.5,
  );

  final positionSizePct = portfolio.totalPortfolioValueInr > 0
      ? (trade.totalAmountInr / portfolio.totalPortfolioValueInr) * 100.0
      : 0.0;

  double maxConcentration = 0.0;
  if (portfolio.holdings.isNotEmpty && portfolio.totalPortfolioValueInr > 0) {
    for (final h in portfolio.holdings) {
      final share =
          (h.currentValueInr / portfolio.totalPortfolioValueInr) * 100.0;
      if (share > maxConcentration) maxConcentration = share;
    }
  }

  final disciplineResult = DisciplineReasonCodeEvaluator.analyze(
    currentRiskScore: riskResult.score,
    positionSizePercentage: positionSizePct,
    usedStopLoss: hasStopLoss,
    portfolioConcentration: maxConcentration,
    tradeFrequency24h: 1,
  );

  final coachContext = CoachContextBuilder.fromTradeAndPortfolio(
    trade: trade,
    portfolio: portfolio,
    riskScore: riskResult.score,
    disciplineScore: disciplineResult.score,
    riskReasonCodes: riskResult.reasonCodes,
    disciplineReasonCodes: disciplineResult.reasonCodes,
  );

  final orchestrator = ref.watch(coachOrchestratorProvider);

  final feedback = await orchestrator.getCoachResponse(
    coachContext,
    userId: trade.userId,
  );

  return CoachResult(
    trade: trade,
    disciplineScore: disciplineResult.score,
    riskScore: riskResult.score,
    coachFeedback: feedback,
  );
});

class CoachResultScreen extends ConsumerWidget {
  final String tradeId;
  const CoachResultScreen({super.key, required this.tradeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(
      connectivityProvider
          .select((status) => status == ConnectivityStatus.offline),
    );
    final resultAsync = ref.watch(coachResultProvider(tradeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach Trade Explanation'),
      ),
      body: isOffline
          ? const Center(
              child: OfflineStateWidget(
                title: 'AI Coach Unavailable',
                message: AppStrings.coachOfflineMessage,
              ),
            )
          : resultAsync.when(
              data: (result) {
                if (result == null) {
                  return const Center(child: Text('Trade Not Found'));
                }
                final feedback = result.coachFeedback;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TradeCard(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'Discipline Score',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${result.disciplineScore.score}/100',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.discipline,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.textSecondary,
                            ),
                            Column(
                              children: [
                                const Text(
                                  'Risk Score',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${result.riskScore.score}/100',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.profit,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'AI Coach Analysis',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _buildExplanationCard(
                        context,
                        title: 'What Was Done Well',
                        content: feedback.whatDoneWell,
                        icon: Icons.check_circle_outline,
                        color: AppColors.profit,
                      ),
                      _buildExplanationCard(
                        context,
                        title: 'What Increased Risk',
                        content: feedback.whatIncreasedRisk,
                        icon: Icons.warning_amber_outlined,
                        color: AppColors.discipline,
                      ),
                      _buildExplanationCard(
                        context,
                        title: 'Key Educational Takeaway',
                        content: feedback.whatToLearn,
                        icon: Icons.school_outlined,
                        color: AppColors.primary,
                      ),
                      _buildExplanationCard(
                        context,
                        title: 'What To Consider Next',
                        content: feedback.whatToConsiderNext,
                        icon: Icons.lightbulb_outline,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => context.go('/home'),
                          child: const Text('BACK TO DASHBOARD'),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Center(
                child: OfflineStateWidget(
                  title: 'AI Coach Unavailable',
                  message: AppStrings.coachOfflineMessage,
                ),
              ),
            ),
    );
  }

  Widget _buildExplanationCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return TradeCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}
