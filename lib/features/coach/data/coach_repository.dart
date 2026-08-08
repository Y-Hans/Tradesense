import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/coach_state.dart';
import 'package:uuid/uuid.dart';

part 'coach_repository.g.dart';

class CoachRepository {
  final _uuid = const Uuid();
  
  Future<List<ChatMessage>> fetchHistory() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      ChatMessage(
        id: _uuid.v4(),
        text: 'Hello Trader. Welcome to TradeSense AI Coach. Ready to review your latest simulated BTC order?',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ];
  }

  Future<ChatMessage> sendMessage(String text) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ChatMessage(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  Future<ChatMessage> getCoachResponse(String userText) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Dynamic context-driven AI coach response abstraction
    final lowerText = userText.toLowerCase();
    String responseText;
    
    if (lowerText.contains('fomo') || lowerText.contains('chase') || lowerText.contains('late')) {
      responseText = 'Entering trades driven by FOMO exposes your portfolio to high volatility. Establish a strict pre-trade setup checklist to verify risk/reward ratio before order execution.';
    } else if (lowerText.contains('stop') || lowerText.contains('loss')) {
      responseText = 'Automated stop-loss orders protect capital against severe price swings. Always define your maximum risk limit before placing market buy orders.';
    } else if (lowerText.contains('size') || lowerText.contains('risk') || lowerText.contains('leverage')) {
      responseText = 'Disciplined position sizing ensures single trades do not compromise total portfolio equity. Keep individual allocations within recommended risk boundaries.';
    } else {
      responseText = 'TradeSense AI Coach: Analyzing setup for "$userText". Maintaining process discipline and setting stop-loss boundaries preserves capital over long trading horizons.';
    }

    return ChatMessage(
      id: _uuid.v4(),
      text: responseText,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  Future<String> getInsights(String routeName) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (routeName == '/' || routeName.contains('dashboard')) {
      return "Your portfolio is well diversified, but your discipline score could improve. Try setting strict stop losses on your next trades.";
    } else if (routeName.contains('trade') || routeName.contains('markets')) {
      return "Current market volatility is high. Ensure you define a clear risk/reward ratio before entering any position.";
    } else {
      return "Keep an eye on your overall risk exposure and always stick to your trading plan.";
    }
  }
}

@riverpod
CoachRepository coachRepository(CoachRepositoryRef ref) {
  return CoachRepository();
}
