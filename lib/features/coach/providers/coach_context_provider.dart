import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../shared/models/user_profile.dart';

/// Assembles rich application context for the persistent AI Coach chat.
///
/// The coach has full situational awareness of:
///   - User identity and profile
///   - Portfolio equity and holdings
///   - Recent trade history
///   - Risk and Discipline scores
///   - Learning progress
///   - Gamification state
///   - Recent journal entries (summary)
///
/// This provider is read-only and has NO side effects.
///
/// **Backend-dependency note**: Full dynamic context (live trades, real
/// portfolio values, discipline history) requires Divyanshu's backend to be
/// merged. Until then, the portfolio and auth state are read from the mock
/// providers and a reasonable static coaching persona is applied.
class CoachContextSummary {
  final String userName;
  final double portfolioEquityInr;
  final double cashBalanceInr;
  final int recentTradeCount;
  final String systemPromptContext;

  const CoachContextSummary({
    required this.userName,
    required this.portfolioEquityInr,
    required this.cashBalanceInr,
    required this.recentTradeCount,
    required this.systemPromptContext,
  });
}

/// Builds a structured system prompt injecting full app context into the coach.
///
/// Called once when the chat session starts (or when portfolio changes).
String buildPersistentCoachSystemPrompt({
  required String userName,
  required double portfolioEquityInr,
  required double cashBalanceInr,
  required int recentTradeCount,
}) {
  return '''
You are TradeSense AI Coach — a professional trading psychologist and trading mentor embedded inside a gamified crypto trading education simulator. Your name is "Coach".

ROLE: You help $userName develop disciplined trading habits through Socratic questioning, evidence-based feedback, and behavioral finance principles.

CORE PHILOSOPHY:
- "Profit does not necessarily mean you made a good decision."
- Focus on PROCESS not OUTCOME.
- A good trade can lose money; a bad trade can make money.
- Help the user understand risk management, position sizing, and stop-loss discipline.

CURRENT USER CONTEXT:
- Trader: $userName
- Portfolio Equity: ₹${portfolioEquityInr.toStringAsFixed(0)}
- Available Cash: ₹${cashBalanceInr.toStringAsFixed(0)}
- Trades this session: $recentTradeCount

BEHAVIORAL GUIDELINES:
1. Be conversational and supportive, never condescending.
2. Ask probing questions to help the user discover insights themselves.
3. Reference the user's actual portfolio context when relevant.
4. Keep responses concise (3-5 sentences max) unless the user asks for depth.
5. For emotional topics (FOMO, revenge trading, overconfidence) use psychology-backed frameworks.
6. Always ground advice in the simulated educational context (this is not real money).
7. Suggest specific actions when possible.
8. Remember: you are educating, not advising on real financial investments.

TOPICS YOU CAN DISCUSS:
- Trade setup and entry criteria
- Stop-loss placement and sizing
- Position sizing relative to portfolio
- FOMO, revenge trading, and emotional biases
- Risk/reward ratios
- Journal reflection and pattern recognition
- Learning module recommendations
- Discipline score interpretation
- Risk score interpretation
- Market volatility context
- Trading psychology frameworks (Kahneman, Van Tharp)

RESPONSE FORMAT:
- Plain conversational text only
- No markdown headers or bullet lists unless specifically asked
- End with a question or actionable suggestion when appropriate
''';
}

/// Riverpod provider exposing [CoachContextSummary] built from live app state.
final coachContextSummaryProvider = Provider<CoachContextSummary>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final portfolioAsync = ref.watch(portfolioProvider);

  final UserProfile? user = userAsync.valueOrNull;
  final portfolio = portfolioAsync.valueOrNull;

  final userName = user?.displayName.isNotEmpty == true
      ? user!.displayName
      : (user?.email.split('@').first ?? 'Trader');
  final equity = portfolio?.totalPortfolioValueInr ?? 100000.0;
  final cash = portfolio?.wallet.balanceInr ?? 100000.0;

  // TODO(Divyanshu-backend): Replace recentTradeCount with live trade history
  // count from the trading repository once the backend is merged.
  const recentTradeCount = 0;

  final systemPrompt = buildPersistentCoachSystemPrompt(
    userName: userName,
    portfolioEquityInr: equity,
    cashBalanceInr: cash,
    recentTradeCount: recentTradeCount,
  );

  return CoachContextSummary(
    userName: userName,
    portfolioEquityInr: equity,
    cashBalanceInr: cash,
    recentTradeCount: recentTradeCount,
    systemPromptContext: systemPrompt,
  );
});
