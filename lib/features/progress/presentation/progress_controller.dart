import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/progress_state.dart';
import '../data/progress_repository.dart';

part 'progress_controller.g.dart';

@riverpod
class ProgressController extends _$ProgressController {
  @override
  FutureOr<ProgressState> build() async {
    return _fetchData();
  }

  Future<ProgressState> _fetchData() async {
    try {
      final repo = ref.read(progressRepositoryProvider);
      return await repo.fetchProgress();
    } catch (e) {
      return ProgressState(
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
