import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/models/trade.dart';

class CoachResultScreen extends ConsumerWidget {
  final String tradeId;
  const CoachResultScreen({super.key, required this.tradeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intelRepo = ref.watch(intelligenceRepositoryProvider);
    final portfolioAsync = ref.watch(portfolioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach Trade Explanation'),
      ),
      body: portfolioAsync.when(
        data: (portfolio) => FutureBuilder(
          future: intelRepo.analyzeTrade(
            Trade(
              id: tradeId,
              userId: 'user_1',
              symbol: 'BTC',
              side: TradeSide.buy,
              type: OrderType.market,
              quantity: 0.1,
              executionPriceInr: 5850000.0,
              totalAmountInr: 585000.0,
              stopLossPriceInr: 5557500.0,
              timestamp: DateTime.now(),
              disciplineScoreAtTrade: 85,
              riskScoreAtTrade: 35,
            ),
            portfolio,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final analysis = snapshot.data!;
            final feedback = analysis.coachFeedback;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: AppColors.card,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Discipline Score',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              Text('${analysis.disciplineScore.score}/100',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.discipline)),
                            ],
                          ),
                          Container(
                              width: 1,
                              height: 40,
                              color: AppColors.textSecondary),
                          Column(
                            children: [
                              const Text('Risk Score',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              Text('${analysis.riskScore.score}/100',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.profit)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('AI Coach Analysis',
                      style: Theme.of(context).textTheme.titleLarge),
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
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Text('Error: $err'),
      ),
    );
  }

  Widget _buildExplanationCard(BuildContext context,
      {required String title,
      required String content,
      required IconData icon,
      required Color color}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
