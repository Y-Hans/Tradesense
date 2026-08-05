import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/profile_state.dart';

part 'profile_repository.g.dart';

class ProfileRepository {
  Future<UserProfile> fetchProfile({String? name, String? email}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final displayName = (name != null && name.trim().isNotEmpty) ? name.trim() : 'Trader';
    final userEmail = (email != null && email.trim().isNotEmpty) ? email.trim() : 'trader@tradesense.app';
    return UserProfile(
      name: displayName,
      email: userEmail,
      accountType: 'Pro Coach Plan',
      joinDate: DateTime.now().subtract(const Duration(days: 45)),
    );
  }

  Future<void> updateNotificationPreference(bool enabled) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepository();
}
