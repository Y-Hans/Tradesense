import 'package:freezed_annotation/freezed_annotation.dart';

part 'journal_state.freezed.dart';

@freezed
class Trade with _$Trade {
  const factory Trade({
    required String id,
    required String symbol,
    required String type, // e.g. Long, Short
    required double pnl,
    required DateTime date,
    required List<String> tags,
    @Default(false) bool aiReviewed,
  }) = _Trade;
}

@freezed
class JournalState with _$JournalState {
  const factory JournalState({
    @Default(true) bool isLoading,
    @Default(false) bool isOffline,
    String? error,
    @Default([]) List<Trade> trades,
  }) = _JournalState;
}
