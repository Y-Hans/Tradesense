import 'package:flutter/foundation.dart';
import '../../../../shared/models/coach_request.dart';

/// DTO representing an individual message in OpenRouter Chat Completions.
@immutable
class OpenRouterMessageDto {
  final String role;
  final String content;

  const OpenRouterMessageDto({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };

  factory OpenRouterMessageDto.fromJson(Map<String, dynamic> json) =>
      OpenRouterMessageDto(
        role: json['role'] as String? ?? '',
        content: json['content'] as String? ?? '',
      );
}

/// DTO representing a request payload sent to OpenRouter POST /chat/completions.
@immutable
class OpenRouterRequestDto {
  final String model;
  final List<OpenRouterMessageDto> messages;
  final Map<String, dynamic>? responseFormat;

  const OpenRouterRequestDto({
    required this.model,
    required this.messages,
    this.responseFormat = const {'type': 'json_object'},
  });

  Map<String, dynamic> toJson() => {
        'model': model,
        'messages': messages.map((m) => m.toJson()).toList(),
        if (responseFormat != null) 'response_format': responseFormat,
      };
}

/// DTO representing an individual completion choice in OpenRouter API response.
@immutable
class OpenRouterChoiceDto {
  final OpenRouterMessageDto message;
  final String? finishReason;

  const OpenRouterChoiceDto({
    required this.message,
    this.finishReason,
  });

  factory OpenRouterChoiceDto.fromJson(Map<String, dynamic> json) =>
      OpenRouterChoiceDto(
        message: OpenRouterMessageDto.fromJson(
          Map<String, dynamic>.from(json['message'] as Map? ?? {}),
        ),
        finishReason: json['finish_reason'] as String?,
      );
}

/// DTO representing a top-level response payload received from OpenRouter API.
@immutable
class OpenRouterResponseDto {
  final String? id;
  final List<OpenRouterChoiceDto> choices;

  const OpenRouterResponseDto({
    this.id,
    required this.choices,
  });

  factory OpenRouterResponseDto.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'] as List? ?? [];
    return OpenRouterResponseDto(
      id: json['id'] as String?,
      choices: rawChoices
          .map((c) => OpenRouterChoiceDto.fromJson(
                Map<String, dynamic>.from(c as Map),
              ))
          .toList(),
    );
  }
}

/// DTO representing structured educational feedback content inside OpenRouter message payload.
@immutable
class OpenRouterCoachFeedbackDto {
  final String? whatDoneWell;
  final String? whatIncreasedRisk;
  final String? whatToLearn;
  final String? whatToConsiderNext;

  const OpenRouterCoachFeedbackDto({
    this.whatDoneWell,
    this.whatIncreasedRisk,
    this.whatToLearn,
    this.whatToConsiderNext,
  });

  factory OpenRouterCoachFeedbackDto.fromJson(Map<String, dynamic> json) {
    return OpenRouterCoachFeedbackDto(
      whatDoneWell: json['what_done_well'] as String?,
      whatIncreasedRisk: json['what_increased_risk'] as String?,
      whatToLearn: json['what_to_learn'] as String?,
      whatToConsiderNext: json['what_to_consider_next'] as String?,
    );
  }

  /// Checks whether all required educational feedback sections are present and non-empty.
  bool get isValid {
    return (whatDoneWell?.trim().isNotEmpty ?? false) &&
        (whatIncreasedRisk?.trim().isNotEmpty ?? false) &&
        (whatToLearn?.trim().isNotEmpty ?? false) &&
        (whatToConsiderNext?.trim().isNotEmpty ?? false);
  }

  /// Converts valid [OpenRouterCoachFeedbackDto] into domain model [CoachResponse].
  CoachResponse toDomain({
    required String aiProvider,
    required String modelId,
    required String promptVersion,
    required int latencyMs,
  }) {
    if (!isValid) {
      throw const FormatException(
        'Cannot convert invalid OpenRouterCoachFeedbackDto to CoachResponse',
      );
    }
    return CoachResponse(
      whatDoneWell: whatDoneWell!.trim(),
      whatIncreasedRisk: whatIncreasedRisk!.trim(),
      whatToLearn: whatToLearn!.trim(),
      whatToConsiderNext: whatToConsiderNext!.trim(),
      aiProvider: aiProvider,
      modelId: modelId,
      promptVersion: promptVersion,
      latencyMs: latencyMs,
    );
  }
}
