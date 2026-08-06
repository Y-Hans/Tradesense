class MissionProgress {
  final String missionId;
  final bool isCompleted;
  final DateTime? completedAt;
  final int xpEarned;

  const MissionProgress({
    required this.missionId,
    this.isCompleted = false,
    this.completedAt,
    this.xpEarned = 0,
  });

  MissionProgress copyWith({
    bool? isCompleted,
    DateTime? completedAt,
    int? xpEarned,
  }) {
    return MissionProgress(
      missionId: missionId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      xpEarned: xpEarned ?? this.xpEarned,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissionProgress &&
          runtimeType == other.runtimeType &&
          missionId == other.missionId &&
          isCompleted == other.isCompleted &&
          xpEarned == other.xpEarned;

  @override
  int get hashCode =>
      missionId.hashCode ^ isCompleted.hashCode ^ xpEarned.hashCode;

  @override
  String toString() =>
      'MissionProgress(missionId: $missionId, isCompleted: $isCompleted, xpEarned: $xpEarned)';
}
