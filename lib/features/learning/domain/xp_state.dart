class XpRewardLog {
  final String eventId;
  final String missionId;
  final int xpAwarded;
  final DateTime timestamp;

  const XpRewardLog({
    required this.eventId,
    required this.missionId,
    required this.xpAwarded,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XpRewardLog &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          missionId == other.missionId &&
          xpAwarded == other.xpAwarded;

  @override
  int get hashCode =>
      eventId.hashCode ^ missionId.hashCode ^ xpAwarded.hashCode;

  @override
  String toString() =>
      'XpRewardLog(eventId: $eventId, missionId: $missionId, xpAwarded: $xpAwarded)';
}

class XpState {
  final int totalXp;
  final Set<String> processedEventIds;
  final Set<String> completedMissionIds;
  final List<XpRewardLog> rewardHistory;

  const XpState({
    this.totalXp = 0,
    this.processedEventIds = const {},
    this.completedMissionIds = const {},
    this.rewardHistory = const [],
  });

  XpState copyWith({
    int? totalXp,
    Set<String>? processedEventIds,
    Set<String>? completedMissionIds,
    List<XpRewardLog>? rewardHistory,
  }) {
    return XpState(
      totalXp: totalXp ?? this.totalXp,
      processedEventIds: processedEventIds ?? this.processedEventIds,
      completedMissionIds: completedMissionIds ?? this.completedMissionIds,
      rewardHistory: rewardHistory ?? this.rewardHistory,
    );
  }

  bool isEventProcessed(String eventId) => processedEventIds.contains(eventId);
  bool isMissionCompleted(String missionId) =>
      completedMissionIds.contains(missionId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XpState &&
          runtimeType == other.runtimeType &&
          totalXp == other.totalXp &&
          processedEventIds.length == other.processedEventIds.length &&
          completedMissionIds.length == other.completedMissionIds.length;

  @override
  int get hashCode =>
      totalXp.hashCode ^
      processedEventIds.length.hashCode ^
      completedMissionIds.length.hashCode;

  @override
  String toString() =>
      'XpState(totalXp: $totalXp, processedEvents: ${processedEventIds.length}, completedMissions: ${completedMissionIds.length})';
}
