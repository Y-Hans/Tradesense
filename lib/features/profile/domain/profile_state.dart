import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_state.freezed.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String name,
    required String email,
    required String accountType,
    required DateTime joinDate,
  }) = _UserProfile;
}

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default(true) bool isLoading,
    String? error,
    UserProfile? profile,
    @Default(true) bool pushNotificationsEnabled,
    @Default(false) bool darkThemeEnabled,
  }) = _ProfileState;
}
