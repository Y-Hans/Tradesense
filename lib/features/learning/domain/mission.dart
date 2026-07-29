import 'learning_event.dart';

class Mission {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final LearningEventType eventType;
  final bool isCompleted;
  final DateTime? completedAt;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.eventType,
    this.isCompleted = false,
    this.completedAt,
  });

  Mission copyWith({
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Mission(
      id: id,
      title: title,
      description: description,
      xpReward: xpReward,
      eventType: eventType,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static const List<Mission> initialMissions = [
    Mission(
      id: 'm1_onboarding',
      title: 'Complete Onboarding',
      description:
          'Finish the onboarding walkthrough to understand risk-free trading principles.',
      xpReward: 50,
      eventType: LearningEventType.onboardingCompleted,
    ),
    Mission(
      id: 'm2_login',
      title: 'First Login',
      description: 'Sign in and authenticate your TradeSense account.',
      xpReward: 30,
      eventType: LearningEventType.loginCompleted,
    ),
    Mission(
      id: 'm3_view_market',
      title: 'View Market',
      description:
          'Explore live market data, asset prices, and trading charts.',
      xpReward: 30,
      eventType: LearningEventType.viewedMarket,
    ),
    Mission(
      id: 'm4_first_trade',
      title: 'First Virtual Trade',
      description:
          'Execute your first simulated cryptocurrency order risk-free.',
      xpReward: 50,
      eventType: LearningEventType.firstTradeCompleted,
    ),
    Mission(
      id: 'm5_read_education',
      title: 'Read Educational Content',
      description:
          'Read educational guides and safety disclaimers to learn risk management.',
      xpReward: 40,
      eventType: LearningEventType.completedLesson,
    ),
    Mission(
      id: 'm6_news_detective',
      title: 'Complete News Detective',
      description:
          'Analyze market headlines and detect sensational news red flags.',
      xpReward: 100,
      eventType: LearningEventType.newsDetectiveCompleted,
    ),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mission &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => id.hashCode ^ isCompleted.hashCode;

  @override
  String toString() =>
      'Mission(id: $id, title: $title, xp: $xpReward, isCompleted: $isCompleted)';
}
