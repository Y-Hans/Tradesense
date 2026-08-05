import 'package:freezed_annotation/freezed_annotation.dart';

part 'today_state.freezed.dart';

@freezed
class TodayState with _$TodayState {
  const factory TodayState({
    @Default(true) bool isLoading,
    @Default(false) bool isOffline,
    @Default(false) bool isEmpty,
    String? error,
    @Default(0) int readinessScore,
    String? greeting,
    String? coachInsightTitle,
    String? coachInsightContent,
    String? actionTitle,
    String? actionDescription,
  }) = _TodayState;
}
