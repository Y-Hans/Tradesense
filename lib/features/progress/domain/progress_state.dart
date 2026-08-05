import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress_state.freezed.dart';

@freezed
class MistakePattern with _$MistakePattern {
  const factory MistakePattern({
    required String name,
    required int frequency,
    required double impactCost,
  }) = _MistakePattern;
}

@freezed
class ProgressState with _$ProgressState {
  const factory ProgressState({
    @Default(true) bool isLoading,
    String? error,
    @Default(0) int overallDisciplineScore,
    @Default(0) int winRatePercentage,
    @Default(0.0) double profitFactor,
    @Default([]) List<MistakePattern> topMistakes,
  }) = _ProgressState;
}
