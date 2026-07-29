class Mission {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final bool isCompleted;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    this.isCompleted = false,
  });

  Mission copyWith({bool? isCompleted}) {
    return Mission(
      id: id,
      title: title,
      description: description,
      xpReward: xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  static const List<Mission> coreMissions = [
    Mission(
      id: 'm1_first_trade',
      title: 'First Trade',
      description:
          'Execute your first simulated crypto trade using virtual funds.',
      xpReward: 50,
    ),
    Mission(
      id: 'm2_explore_market',
      title: 'Explore the Market',
      description:
          'View real-time prices and order books for at least 3 cryptocurrencies.',
      xpReward: 30,
    ),
    Mission(
      id: 'm3_use_stop_loss',
      title: 'Use a Stop-Loss',
      description:
          'Set a stop-loss order to protect your simulated position from steep drawdowns.',
      xpReward: 100,
    ),
    Mission(
      id: 'm4_reduce_risk',
      title: 'Reduce Portfolio Risk',
      description:
          'Diversify your virtual holdings across multiple assets to lower volatility risk.',
      xpReward: 100,
    ),
    Mission(
      id: 'm5_discipline_80',
      title: 'Reach Discipline Score >= 80',
      description:
          'Maintain high trading discipline with proper position sizing and stop-loss usage.',
      xpReward: 150,
    ),
  ];
}
