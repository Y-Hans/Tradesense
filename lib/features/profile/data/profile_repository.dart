import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/profile_state.dart';

part 'profile_repository.g.dart';

class ProfileRepository {
  final SupabaseClient? _client;

  ProfileRepository([SupabaseClient? client]) : _client = client;

  SupabaseClient? get _safeClient {
    try {
      return _client ?? Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<UserProfile> fetchProfile({String? name, String? email}) async {
    final client = _safeClient;
    final user = client?.auth.currentUser;
    if (user != null) {
      final resp = await client!
          .from('profiles')
          .select('id, email, display_name, is_premium, created_at')
          .eq('id', user.id)
          .maybeSingle();

      if (resp != null) {
        final displayName = (resp['display_name'] as String?) ?? name ?? 'Trader';
        final userEmail = (resp['email'] as String?) ?? email ?? user.email ?? 'trader@tradesense.app';
        final isPremium = resp['is_premium'] as bool? ?? false;
        final createdAtStr = resp['created_at'] as String?;
        final joinDate = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();

        return UserProfile(
          name: displayName,
          email: userEmail,
          accountType: isPremium ? 'Premium Trader' : 'Free Learning Tier',
          joinDate: joinDate,
        );
      }
    }

    final displayName = (name != null && name.trim().isNotEmpty) ? name.trim() : 'Trader';
    final userEmail = (email != null && email.trim().isNotEmpty) ? email.trim() : 'trader@tradesense.app';
    return UserProfile(
      name: displayName,
      email: userEmail,
      accountType: 'Free Learning Tier',
      joinDate: DateTime.now(),
    );
  }

  Future<void> updateNotificationPreference(bool enabled) async {
    // Persist notification preferences
  }
}

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepository();
}
