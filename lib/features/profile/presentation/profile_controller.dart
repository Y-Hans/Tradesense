import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/profile_state.dart';
import '../data/profile_repository.dart';

import '../../onboarding/data/onboarding_repository.dart';
import '../../../core/providers/app_providers.dart';

part 'profile_controller.g.dart';

@riverpod
class ProfileController extends _$ProfileController {
  @override
  FutureOr<ProfileState> build() async {
    final repo = ref.watch(profileRepositoryProvider);
    final onboardingRepo = ref.watch(onboardingRepositoryProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    
    final name = currentUser?.displayName ?? onboardingRepo.userName;
    final email = currentUser?.email;
    
    final profile = await repo.fetchProfile(name: name, email: email);
    return ProfileState(
      isLoading: false,
      profile: profile,
    );
  }

  Future<void> toggleNotifications(bool value) async {
    state = AsyncValue.data(
      state.requireValue.copyWith(pushNotificationsEnabled: value),
    );
    try {
      await ref.read(profileRepositoryProvider).updateNotificationPreference(value);
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(
        state.requireValue.copyWith(pushNotificationsEnabled: !value),
      );
    }
  }

  void toggleTheme(bool value) {
    state = AsyncValue.data(
      state.requireValue.copyWith(darkThemeEnabled: value),
    );
  }

  Future<void> signOut() async {
    // Stub implementation for signing out
  }
}
