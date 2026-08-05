import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/today_state.dart';
import '../data/today_repository.dart';

import '../../onboarding/data/onboarding_repository.dart';
import '../../../core/providers/app_providers.dart';

part 'today_controller.g.dart';

@riverpod
class TodayController extends _$TodayController {
  @override
  FutureOr<TodayState> build() async {
    return _fetchData();
  }

  Future<TodayState> _fetchData() async {
    try {
      final repo = ref.read(todayRepositoryProvider);
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      final userProfile = await ref.read(currentUserProvider.future).catchError((_) => null);
      
      final userName = userProfile?.displayName ?? onboardingRepo.userName;
      return await repo.fetchTodayDashboard(userName: userName);
    } catch (e) {
      return TodayState(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData());
  }

  void acceptActionPlan() {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        current.copyWith(
          actionTitle: 'Action Plan Added to Focus',
          actionDescription: 'Pre-market routine active. AI Coach will track discipline for today\'s session.',
        ),
      );
    }
  }

  void dismissActionPlan() {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        current.copyWith(
          actionTitle: null,
          actionDescription: null,
        ),
      );
    }
  }

  void setOfflineState() {
    state = const AsyncValue.data(TodayState(isLoading: false, isOffline: true));
  }
}
