import 'dart:async';

import 'package:cryptoedu/core/contracts/provider_contracts.dart';
import 'package:cryptoedu/features/coach/domain/coach_context.dart';
import 'package:cryptoedu/features/coach/domain/coach_context_builder.dart';
import 'package:cryptoedu/features/coach/domain/coach_orchestrator.dart';
import 'package:cryptoedu/features/coach/domain/fallback_coach.dart';
import 'package:cryptoedu/features/intelligence/domain/reason_code.dart';
import 'package:cryptoedu/shared/models/coach_request.dart';
import 'package:cryptoedu/shared/models/discipline_score.dart';
import 'package:cryptoedu/shared/models/risk_score.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Test-only fake AIProvider — no OpenRouter, Supabase, or network dependency.
// ---------------------------------------------------------------------------

class _FakeAIProvider implements AIProvider {
  int invocationCount = 0;
  CoachRequest? lastRequest;

  CoachResponse? responseToReturn;
  Exception? exceptionToThrow;

  @override
  Future<CoachResponse> generateCoachFeedback(CoachRequest request) async {
    invocationCount++;
    lastRequest = request;

    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }

    return responseToReturn!;
  }
}

// ---------------------------------------------------------------------------
// Shared test fixtures
// ---------------------------------------------------------------------------

const _lowRiskScore = RiskScore(
  score: 20,
  level: RiskLevel.low,
  concentrationScore: 10.0,
  sizingScore: 10.0,
  volatilityScore: 15.0,
  stopLossScore: 0.0,
  explanations: ['Low risk'],
);

const _highRiskScore = RiskScore(
  score: 75,
  level: RiskLevel.high,
  concentrationScore: 80.0,
  sizingScore: 70.0,
  volatilityScore: 60.0,
  stopLossScore: 100.0,
  explanations: ['High risk'],
);

const _highDisciplineScore = DisciplineScore(
  score: 95,
  riskMgmtScore: 100.0,
  positionSizingScore: 100.0,
  stopLossDisciplineScore: 100.0,
  concentrationScore: 100.0,
  frequencyScore: 100.0,
  breakdownNotes: ['Disciplined'],
);

const _lowDisciplineScore = DisciplineScore(
  score: 30,
  riskMgmtScore: 0.0,
  positionSizingScore: 20.0,
  stopLossDisciplineScore: 0.0,
  concentrationScore: 40.0,
  frequencyScore: 0.0,
  breakdownNotes: ['Poor discipline'],
);

const _goodRiskCodes = [
  RiskReasonCode.balancedConcentration,
  RiskReasonCode.controlledPositionSize,
  RiskReasonCode.normalVolatility,
  RiskReasonCode.stopLossPresent,
];

const _goodDisciplineCodes = [
  DisciplineReasonCode.goodRiskManagement,
  DisciplineReasonCode.disciplinedPositionSize,
  DisciplineReasonCode.usedStopLoss,
  DisciplineReasonCode.controlledConcentration,
  DisciplineReasonCode.controlledTradingFrequency,
];

const _adverseRiskCodes = [
  RiskReasonCode.highConcentration,
  RiskReasonCode.largePositionSize,
  RiskReasonCode.elevatedVolatility,
  RiskReasonCode.noStopLoss,
];

const _adverseDisciplineCodes = [
  DisciplineReasonCode.poorRiskManagement,
  DisciplineReasonCode.excessivePositionSize,
  DisciplineReasonCode.missingStopLoss,
  DisciplineReasonCode.highConcentration,
  DisciplineReasonCode.highTradingFrequency,
];

const _validAIResponse = CoachResponse(
  whatDoneWell: 'Your disciplined stop-loss placement showed strong process.',
  whatIncreasedRisk:
      'Concentration in a single asset increased portfolio volatility.',
  whatToLearn:
      'Understanding position sizing rules helps manage downside exposure.',
  whatToConsiderNext:
      'Review your asset allocation before entering the next simulated trade.',
  aiProvider: 'OpenRouter',
  modelId: 'anthropic/claude-3.5-sonnet',
  promptVersion: 'v1.0.0',
  latencyMs: 1200,
);

const _malformedResponse = CoachResponse(
  whatDoneWell: '',
  whatIncreasedRisk: 'Some warning text',
  whatToLearn: '',
  whatToConsiderNext: 'Some next step',
  aiProvider: 'OpenRouter',
  modelId: 'anthropic/claude-3.5-sonnet',
  promptVersion: 'v1.0.0',
  latencyMs: 800,
);

CoachContext _buildGoodContext() {
  return CoachContextBuilder.build(
    symbol: 'BTC',
    side: TradeSide.buy,
    quantity: 0.01,
    executionPriceInr: 5000000.0,
    totalTradeValueInr: 50000.0,
    hasStopLoss: true,
    stopLossPriceInr: 4800000.0,
    tradeId: 'trade-orch-001',
    totalEquityInr: 1000000.0,
    virtualCashBalanceInr: 950000.0,
    riskScore: _lowRiskScore,
    disciplineScore: _highDisciplineScore,
    riskReasonCodes: _goodRiskCodes,
    disciplineReasonCodes: _goodDisciplineCodes,
  );
}

CoachContext _buildAdverseContext() {
  return CoachContextBuilder.build(
    symbol: 'SOL',
    side: TradeSide.buy,
    quantity: 50.0,
    executionPriceInr: 15000.0,
    totalTradeValueInr: 750000.0,
    hasStopLoss: false,
    totalEquityInr: 1000000.0,
    virtualCashBalanceInr: 250000.0,
    riskScore: _highRiskScore,
    disciplineScore: _lowDisciplineScore,
    riskReasonCodes: _adverseRiskCodes,
    disciplineReasonCodes: _adverseDisciplineCodes,
  );
}

// ---------------------------------------------------------------------------
// Test suite
// ---------------------------------------------------------------------------

void main() {
  group('CoachOrchestrator Unit Tests', () {
    late _FakeAIProvider fakeProvider;

    setUp(() {
      fakeProvider = _FakeAIProvider();
    });

    // -----------------------------------------------------------------------
    // Provider Success
    // -----------------------------------------------------------------------

    test('Provider success: returns valid AI response unchanged', () async {
      fakeProvider.responseToReturn = _validAIResponse;

      final orchestrator =
          CoachOrchestrator(aiProvider: fakeProvider, aiEnabled: true);
      final context = _buildGoodContext();

      final response =
          await orchestrator.getCoachResponse(context, userId: 'user-1');

      expect(response.whatDoneWell, equals(_validAIResponse.whatDoneWell));
      expect(response.whatIncreasedRisk,
          equals(_validAIResponse.whatIncreasedRisk));
      expect(response.whatToLearn, equals(_validAIResponse.whatToLearn));
      expect(response.whatToConsiderNext,
          equals(_validAIResponse.whatToConsiderNext));
      expect(response.aiProvider, equals('OpenRouter'));
      expect(response.latencyMs, equals(1200));
      expect(fakeProvider.invocationCount, equals(1));
    });

    test(
        'Provider success: CoachRequest contains structured trade/portfolio data',
        () async {
      fakeProvider.responseToReturn = _validAIResponse;

      final orchestrator =
          CoachOrchestrator(aiProvider: fakeProvider, aiEnabled: true);
      final context = _buildGoodContext();

      await orchestrator.getCoachResponse(context, userId: 'user-42');

      final request = fakeProvider.lastRequest!;
      expect(request.userId, equals('user-42'));
      expect(request.tradeId, equals('trade-orch-001'));
      expect(request.riskScore, equals(20));
      expect(request.disciplineScore, equals(95));

      // Verify structured trade context (not prose)
      expect(request.tradeContext['symbol'], equals('BTC'));
      expect(request.tradeContext['side'], equals('buy'));
      expect(request.tradeContext['quantity'], equals(0.01));
      expect(request.tradeContext['has_stop_loss'], isTrue);

      // Verify structured portfolio context
      expect(request.portfolioContext['total_equity_inr'], equals(1000000.0));

      // Verify reason codes remain machine-readable (stable string codes)
      final riskCodes = request.marketContext['risk_reason_codes'] as List;
      expect(riskCodes, contains('CONCENTRATION_BALANCED'));
      expect(riskCodes, contains('POSITION_SIZE_CONTROLLED'));
      expect(riskCodes, contains('STOP_LOSS_PRESENT'));

      final disciplineCodes =
          request.marketContext['discipline_reason_codes'] as List;
      expect(disciplineCodes, contains('RISK_MANAGEMENT_GOOD'));
      expect(disciplineCodes, contains('STOP_LOSS_USED'));
    });

    // -----------------------------------------------------------------------
    // Provider Failure — Generic Exception & TimeoutException
    // -----------------------------------------------------------------------

    test('Provider failure: generic Exception returns deterministic fallback',
        () async {
      fakeProvider.exceptionToThrow = Exception('Supabase Edge Function error');

      final orchestrator =
          CoachOrchestrator(aiProvider: fakeProvider, aiEnabled: true);
      final context = _buildGoodContext();

      final response =
          await orchestrator.getCoachResponse(context, userId: 'user-1');

      // Verify fallback was used
      expect(response.aiProvider, equals('DeterministicFallback'));
      expect(response.modelId, equals('deterministic-v1'));
      expect(response.latencyMs, equals(0));
      expect(fakeProvider.invocationCount, equals(1));
    });

    test('Provider failure: TimeoutException returns deterministic fallback',
        () async {
      fakeProvider.exceptionToThrow = TimeoutException('Provider timed out');

      final orchestrator =
          CoachOrchestrator(aiProvider: fakeProvider, aiEnabled: true);
      final context = _buildGoodContext();

      final response =
          await orchestrator.getCoachResponse(context, userId: 'user-1');

      expect(response.aiProvider, equals('DeterministicFallback'));
      expect(response.modelId, equals('deterministic-v1'));
      expect(fakeProvider.invocationCount, equals(1));
    });

    // -----------------------------------------------------------------------
    // Feature Disabled
    // -----------------------------------------------------------------------

    test(
        'Feature disabled: provider is NOT invoked, deterministic fallback returned',
        () async {
      fakeProvider.responseToReturn = _validAIResponse;

      final orchestrator =
          CoachOrchestrator(aiProvider: fakeProvider, aiEnabled: false);
      final context = _buildGoodContext();

      final response =
          await orchestrator.getCoachResponse(context, userId: 'user-1');

      expect(response.aiProvider, equals('DeterministicFallback'));
      expect(response.modelId, equals('deterministic-v1'));
      // Provider was never called
      expect(fakeProvider.invocationCount, equals(0));
    });

    // -----------------------------------------------------------------------
    // Malformed Response
    // -----------------------------------------------------------------------

    test(
        'Malformed response: empty feedback fields trigger deterministic fallback',
        () async {
      fakeProvider.responseToReturn = _malformedResponse;

      final orchestrator =
          CoachOrchestrator(aiProvider: fakeProvider, aiEnabled: true);
      final context = _buildGoodContext();

      final response =
          await orchestrator.getCoachResponse(context, userId: 'user-1');

      expect(response.aiProvider, equals('DeterministicFallback'));
      expect(response.modelId, equals('deterministic-v1'));
      // Provider was called but result was rejected
      expect(fakeProvider.invocationCount, equals(1));
    });

    // -----------------------------------------------------------------------
    // Deterministic Fallback Equality
    // -----------------------------------------------------------------------

    test(
        'Deterministic fallback: identical context + failure produces identical response',
        () async {
      fakeProvider.exceptionToThrow = Exception('Provider unavailable');

      final orchestrator =
          CoachOrchestrator(aiProvider: fakeProvider, aiEnabled: true);
      final context = _buildGoodContext();

      final r1 = await orchestrator.getCoachResponse(context, userId: 'user-1');
      final r2 = await orchestrator.getCoachResponse(context, userId: 'user-1');

      expect(r1.whatDoneWell, equals(r2.whatDoneWell));
      expect(r1.whatIncreasedRisk, equals(r2.whatIncreasedRisk));
      expect(r1.whatToLearn, equals(r2.whatToLearn));
      expect(r1.whatToConsiderNext, equals(r2.whatToConsiderNext));
      expect(r1.aiProvider, equals(r2.aiProvider));
      expect(r1.modelId, equals(r2.modelId));
    });

    test(
        'Deterministic fallback: disabled-path and failure-path produce identical fallback for same context',
        () async {
      final context = _buildGoodContext();

      // Disabled path
      final disabledOrch =
          CoachOrchestrator(aiProvider: fakeProvider, aiEnabled: false);
      final disabledResponse =
          await disabledOrch.getCoachResponse(context, userId: 'user-1');

      // Failure path
      fakeProvider.exceptionToThrow = Exception('Network failure');
      final failureOrch =
          CoachOrchestrator(aiProvider: fakeProvider, aiEnabled: true);
      final failureResponse =
          await failureOrch.getCoachResponse(context, userId: 'user-1');

      expect(
          disabledResponse.whatDoneWell, equals(failureResponse.whatDoneWell));
      expect(disabledResponse.whatIncreasedRisk,
          equals(failureResponse.whatIncreasedRisk));
      expect(disabledResponse.whatToLearn, equals(failureResponse.whatToLearn));
      expect(disabledResponse.whatToConsiderNext,
          equals(failureResponse.whatToConsiderNext));
    });

    // -----------------------------------------------------------------------
    // Fallback delegates to existing FallbackCoach
    // -----------------------------------------------------------------------

    test(
        'Fallback reuse: orchestrator fallback matches FallbackCoach.analyze output exactly',
        () async {
      fakeProvider.exceptionToThrow = Exception('Provider outage');

      final orchestrator =
          CoachOrchestrator(aiProvider: fakeProvider, aiEnabled: true);
      final context = _buildAdverseContext();

      final orchResponse =
          await orchestrator.getCoachResponse(context, userId: 'user-1');
      final directFallback = FallbackCoach.analyze(context);

      expect(orchResponse.whatDoneWell, equals(directFallback.whatDoneWell));
      expect(orchResponse.whatIncreasedRisk,
          equals(directFallback.whatIncreasedRisk));
      expect(orchResponse.whatToLearn, equals(directFallback.whatToLearn));
      expect(orchResponse.whatToConsiderNext,
          equals(directFallback.whatToConsiderNext));
      expect(orchResponse.aiProvider, equals(directFallback.aiProvider));
      expect(orchResponse.modelId, equals(directFallback.modelId));
      expect(orchResponse.promptVersion, equals(directFallback.promptVersion));
      expect(orchResponse.latencyMs, equals(directFallback.latencyMs));
    });

    // -----------------------------------------------------------------------
    // Provider Independence
    // -----------------------------------------------------------------------

    test(
        'Provider independence: orchestrator uses abstract AIProvider, no OpenRouter imports',
        () async {
      fakeProvider.responseToReturn = _validAIResponse;

      final orchestrator =
          CoachOrchestrator(aiProvider: fakeProvider, aiEnabled: true);
      final context = _buildGoodContext();

      final response =
          await orchestrator.getCoachResponse(context, userId: 'user-1');
      expect(response, isNotNull);
      expect(fakeProvider.invocationCount, equals(1));
    });

    // -----------------------------------------------------------------------
    // Profit Independence
    // -----------------------------------------------------------------------

    test(
        'Profit independence: orchestration path does not depend on P&L or profitability',
        () async {
      fakeProvider.responseToReturn = _validAIResponse;

      final orchestrator =
          CoachOrchestrator(aiProvider: fakeProvider, aiEnabled: true);

      final r1 = await orchestrator.getCoachResponse(_buildGoodContext(),
          userId: 'user-1');

      final r2 = await orchestrator.getCoachResponse(_buildAdverseContext(),
          userId: 'user-1');

      expect(r1.aiProvider, equals('OpenRouter'));
      expect(r2.aiProvider, equals('OpenRouter'));
      expect(fakeProvider.invocationCount, equals(2));
    });

    // -----------------------------------------------------------------------
    // No Technical Error Leakage
    // -----------------------------------------------------------------------

    test(
        'No technical error leakage: fallback response contains no infrastructure details',
        () async {
      fakeProvider.exceptionToThrow =
          Exception('HTTP 429 Rate Limited by OpenRouter API');

      final orchestrator =
          CoachOrchestrator(aiProvider: fakeProvider, aiEnabled: true);
      final context = _buildAdverseContext();

      final response =
          await orchestrator.getCoachResponse(context, userId: 'user-1');

      final fullText =
          '${response.whatDoneWell} ${response.whatIncreasedRisk} ${response.whatToLearn} ${response.whatToConsiderNext}'
              .toLowerCase();

      expect(fullText, isNot(contains('http')));
      expect(fullText, isNot(contains('429')));
      expect(fullText, isNot(contains('openrouter')));
      expect(fullText, isNot(contains('api key')));
      expect(fullText, isNot(contains('supabase')));
      expect(fullText, isNot(contains('rate limit')));
      expect(fullText, isNot(contains('stack trace')));
      expect(fullText, isNot(contains('exception')));
    });

    // -----------------------------------------------------------------------
    // Valid AI Response Not Rejected
    // -----------------------------------------------------------------------

    test('Valid AI response with non-empty fields is not falsely rejected',
        () async {
      const validResponse = CoachResponse(
        whatDoneWell: 'Good stop-loss placement.',
        whatIncreasedRisk: 'Minor concentration risk.',
        whatToLearn: 'Position sizing fundamentals.',
        whatToConsiderNext: 'Review allocation targets.',
        aiProvider: 'CustomModelProvider',
        modelId: 'custom-v2',
        promptVersion: 'v2.0.0',
        latencyMs: 500,
      );

      fakeProvider.responseToReturn = validResponse;

      final orchestrator =
          CoachOrchestrator(aiProvider: fakeProvider, aiEnabled: true);
      final context = _buildGoodContext();

      final response =
          await orchestrator.getCoachResponse(context, userId: 'user-1');

      expect(response.aiProvider, equals('CustomModelProvider'));
      expect(response.modelId, equals('custom-v2'));
    });
  });
}
