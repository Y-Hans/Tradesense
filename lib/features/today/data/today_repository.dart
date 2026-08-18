import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/today_state.dart';

part 'today_repository.g.dart';

class TodayRepository {
  Future<TodayState> fetchTodayDashboard({String? userName}) async {
    final name = (userName != null && userName.trim().isNotEmpty) ? userName.trim() : 'Trader';
    
    return TodayState(
      isLoading: false,
      isOffline: false,
      isEmpty: false,
      readinessScore: 0,
      greeting: 'Good morning, $name.',
      coachInsightTitle: 'Risk Management Focus',
      coachInsightContent: 'Focus on discipline and proper risk-to-reward ratios today. Ensure every open position has a defined exit strategy.',
      actionTitle: null,
      actionDescription: null,
    );
  }
}

@riverpod
TodayRepository todayRepository(TodayRepositoryRef ref) {
  return TodayRepository();
}
