import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/progress_state.dart';

part 'progress_repository.g.dart';

class ProgressRepository {
  Future<ProgressState> fetchProgress() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const ProgressState(
      isLoading: false,
      overallDisciplineScore: 78,
      winRatePercentage: 54,
      profitFactor: 1.4,
      topMistakes: [
        MistakePattern(name: 'FOMO Entry', frequency: 12, impactCost: 450.0),
        MistakePattern(name: 'Early Exit', frequency: 8, impactCost: 320.0),
        MistakePattern(name: 'Revenge Trade', frequency: 3, impactCost: 800.0),
      ],
    );
  }
}

@riverpod
ProgressRepository progressRepository(ProgressRepositoryRef ref) {
  return ProgressRepository();
}
