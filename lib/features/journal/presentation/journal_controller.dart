import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/journal_state.dart';
import '../data/journal_repository.dart';

part 'journal_controller.g.dart';

@riverpod
class JournalController extends _$JournalController {
  @override
  FutureOr<JournalState> build() async {
    return _fetchData();
  }

  Future<JournalState> _fetchData() async {
    try {
      final trades = await ref.read(journalRepositoryProvider).fetchTrades();
      return JournalState(
        isLoading: false,
        trades: trades,
      );
    } catch (e) {
      return JournalState(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData());
  }
}
