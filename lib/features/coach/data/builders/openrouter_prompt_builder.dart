import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/coach_request.dart';
import '../dtos/openrouter_dtos.dart';

/// Builder responsible for deterministically constructing OpenRouter API request DTOs
/// and prompts from domain [CoachRequest] objects.
@immutable
class OpenRouterPromptBuilder {
  /// Default prompt version identifier.
  static const String defaultPromptVersion = 'v1.0.0';

  /// Version identifier for the prompt template.
  final String promptVersion;

  const OpenRouterPromptBuilder({
    this.promptVersion = defaultPromptVersion,
  });

  /// Constructs a deterministic system prompt instructing the model on output schema and tone.
  String buildSystemPrompt() {
    return '''
You are a disciplined, educational crypto trading coach for a gamified trading simulator.
Your objective is to provide objective, non-judgmental, educational coaching feedback based on simulated trade execution data.

You MUST respond strictly with a valid JSON object containing exactly the following keys:
1. "what_done_well": Positive aspects of trade process, discipline, or risk management.
2. "what_increased_risk": Specific trade or portfolio parameters that elevated risk exposure.
3. "what_to_learn": Educational concept explaining trading mechanics, risk management, or discipline.
4. "what_to_consider_next": Actionable, forward-looking recommendations for subsequent simulated trades.

Do not include any surrounding markdown code fences (such as ```json), introductory text, or concluding commentary. Output ONLY the JSON object.
''';
  }

  /// Constructs a deterministic user prompt from the structured payload inside [CoachRequest].
  String buildUserPrompt(CoachRequest request) {
    final payload = {
      'trade_id': request.tradeId,
      'risk_score': request.riskScore,
      'discipline_score': request.disciplineScore,
      'trade_context': request.tradeContext,
      'portfolio_context': request.portfolioContext,
      'market_context': request.marketContext,
    };
    return 'Analyze the following simulated trade execution context:\n${jsonEncode(payload)}';
  }

  /// Builds a complete [OpenRouterRequestDto] ready for network transmission.
  OpenRouterRequestDto buildRequest(
    CoachRequest request, {
    required String modelId,
  }) {
    final systemMessage = OpenRouterMessageDto(
      role: 'system',
      content: buildSystemPrompt(),
    );
    final userMessage = OpenRouterMessageDto(
      role: 'user',
      content: buildUserPrompt(request),
    );

    return OpenRouterRequestDto(
      model: modelId,
      messages: [systemMessage, userMessage],
      responseFormat: const {'type': 'json_object'},
    );
  }
}
