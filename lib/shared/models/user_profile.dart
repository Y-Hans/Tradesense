import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final double virtualBalanceInr;
  final DateTime createdAt;
  final bool isPremium;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.virtualBalanceInr,
    required this.createdAt,
    this.isPremium = false,
  });

  factory UserProfile.initial(
      {required String id, required String email, String? displayName}) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? email.split('@').first,
      virtualBalanceInr: 100000.0,
      createdAt: DateTime.now(),
      isPremium: false,
    );
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    double? virtualBalanceInr,
    DateTime? createdAt,
    bool? isPremium,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      virtualBalanceInr: virtualBalanceInr ?? this.virtualBalanceInr,
      createdAt: createdAt ?? this.createdAt,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'virtual_balance_inr': virtualBalanceInr,
      'created_at': createdAt.toIso8601String(),
      'is_premium': isPremium,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String? ?? '',
      virtualBalanceInr: (json['virtual_balance_inr'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      isPremium: json['is_premium'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          virtualBalanceInr == other.virtualBalanceInr &&
          createdAt == other.createdAt &&
          isPremium == other.isPremium;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      virtualBalanceInr.hashCode ^
      createdAt.hashCode ^
      isPremium.hashCode;
}
