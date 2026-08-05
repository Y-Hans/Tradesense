import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/today_state.dart';

part 'today_repository.g.dart';

class TodayRepository {
  Future<TodayState> fetchTodayDashboard({String? userName}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    final name = (userName != null && userName.trim().isNotEmpty) ? userName.trim() : 'Trader';
    
    return TodayState(
      isLoading: false,
      isOffline: false,
      isEmpty: false,
      readinessScore: 85,
      greeting: 'Good morning, $name.',
      coachInsightTitle: 'Market alignment',
      coachInsightContent: 'Based on your recent trades, you perform best when taking early momentum plays. Pre-market volume suggests ideal conditions today.',
      actionTitle: 'Pre-market check-in',
      actionDescription: 'Log your state of mind before the bell rings.',
    );
  }
}

@riverpod
TodayRepository todayRepository(TodayRepositoryRef ref) {
  return TodayRepository();
}
