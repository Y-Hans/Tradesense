import 'package:freezed_annotation/freezed_annotation.dart';

part 'coach_state.freezed.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String text,
    required bool isUser,
    required DateTime timestamp,
  }) = _ChatMessage;
}

@freezed
class CoachState with _$CoachState {
  const factory CoachState({
    @Default(true) bool isLoading,
    @Default(false) bool isTyping,
    String? error,
    @Default([]) List<ChatMessage> messages,
  }) = _CoachState;
}
