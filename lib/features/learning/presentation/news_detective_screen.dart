import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/trade_card.dart';

class NewsQuestion {
  final String id;
  final String headline;
  final bool isReal;
  final String explanation;
  final List<String> clues;
  final String sourceMetadata;

  const NewsQuestion({
    required this.id,
    required this.headline,
    required this.isReal,
    required this.explanation,
    required this.clues,
    required this.sourceMetadata,
  });
}

class NewsDetectiveScreen extends StatefulWidget {
  const NewsDetectiveScreen({super.key});

  @override
  State<NewsDetectiveScreen> createState() => _NewsDetectiveScreenState();
}

class _NewsDetectiveScreenState extends State<NewsDetectiveScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _showExplanation = false;
  bool? _lastAnswerCorrect;
  bool _isCompleted = false;

  static const List<NewsQuestion> _questions = [
    NewsQuestion(
      id: 'nq_1',
      headline:
          '[SIMULATED EXERCISE] BREAKING: Secret Central Bank Memo Confirms Global Bitcoin Reserve Standard Starting Tomorrow!',
      isReal: false,
      explanation:
          'FAKE: Sensational clickbait claiming global policy shift without official central bank release or primary source links.',
      clues: [
        'Sensational wording ("Secret Memo")',
        'Unverified source',
        'No official government corroboration'
      ],
      sourceMetadata: 'Unverified Telegram Trading Channel',
    ),
    NewsQuestion(
      id: 'nq_2',
      headline:
          'U.S. SEC Approves First Spot Bitcoin Exchange Traded Funds (ETFs)',
      isReal: true,
      explanation:
          'REAL: Directly verifiable via official SEC public filing releases and mainstream global financial reporting.',
      clues: [
        'Official SEC regulatory filing',
        'Corroborated by Bloomberg & Reuters',
        'Neutral factual reporting'
      ],
      sourceMetadata: 'Official U.S. SEC (sec.gov)',
    ),
    NewsQuestion(
      id: 'nq_3',
      headline:
          '[SIMULATED EXERCISE] GUARANTEED 500% Returns: New AI Trading Bot Never Loses a Single Trade!',
      isReal: false,
      explanation:
          'FAKE: No trading algorithm can guarantee 100% win rate or fixed returns. Financial markets inherently carry risk.',
      clues: [
        'Promotional scam language ("GUARANTEED")',
        'Unsupported certainty',
        'Lack of regulatory audit'
      ],
      sourceMetadata: 'Sponsored Social Media Ad',
    ),
    NewsQuestion(
      id: 'nq_4',
      headline: 'Bitcoin Halving Event Successfully Completed at Block 840,000',
      isReal: true,
      explanation:
          'REAL: Empirically confirmed on public blockchain block explorers as block subsidy halved to 3.125 BTC.',
      clues: [
        'On-chain block explorer data',
        'Deterministic code execution',
        'Global node consensus'
      ],
      sourceMetadata: 'Public Blockchain Explorer',
    ),
    NewsQuestion(
      id: 'nq_5',
      headline:
          '[SIMULATED EXERCISE] Anonymous Whistleblower Claims Ethereum Founders Are Shutting Down Network Next Week',
      isReal: false,
      explanation:
          'FAKE: Ethereum is a decentralized blockchain; single founders cannot shut down decentralized node networks.',
      clues: [
        'Technical impossibility on decentralized network',
        'Relies solely on anonymous claims',
        'No official EIP documentation'
      ],
      sourceMetadata: 'Anonymous Crypto Blogspot',
    ),
  ];

  void _answerQuestion(bool userSelection) {
    if (_showExplanation) return;
    final currentQ = _questions[_currentIndex];
    final isCorrect = (userSelection == currentQ.isReal);

    setState(() {
      _lastAnswerCorrect = isCorrect;
      if (isCorrect) _score++;
      _showExplanation = true;
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 >= _questions.length) {
      setState(() {
        _isCompleted = true;
        _showExplanation = false;
      });
    } else {
      setState(() {
        _currentIndex++;
        _showExplanation = false;
        _lastAnswerCorrect = null;
      });
    }
  }

  void _resetQuiz() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _showExplanation = false;
      _lastAnswerCorrect = null;
      _isCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Detective 🕵️‍♂️'),
      ),
      body: _isCompleted
          ? _buildResultsView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'QUESTION ${_currentIndex + 1} OF ${_questions.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Score: $_score',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TradeCard(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                              'Source: ${_questions[_currentIndex].sourceMetadata}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          const SizedBox(height: 12),
                          Text(
                            _questions[_currentIndex].headline,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          const Text('Clues & Red Flags:',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          const SizedBox(height: 8),
                          ..._questions[_currentIndex]
                              .clues
                              .map((clue) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.search,
                                            size: 14,
                                            color: AppColors.textSecondary),
                                        const SizedBox(width: 6),
                                        Expanded(
                                            child: Text(clue,
                                                style: const TextStyle(
                                                    fontSize: 13))),
                                      ],
                                    ),
                                  )),
                        ],
                      ),
                  ),
                  const SizedBox(height: 20),
                  if (!_showExplanation) ...[
                    const Text('Is this headline REAL or FAKE?',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.profit),
                            onPressed: () => _answerQuestion(true),
                            icon: const Icon(Icons.check_circle_outline,
                                color: Colors.white),
                            label: const Text('REAL NEWS',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.loss),
                            onPressed: () => _answerQuestion(false),
                            icon: const Icon(Icons.cancel_outlined,
                                color: Colors.white),
                            label: const Text('FAKE / CLICKBAIT',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Card(
                      color: _lastAnswerCorrect == true
                          ? AppColors.profit.withValues(alpha: 0.15)
                          : AppColors.loss.withValues(alpha: 0.15),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _lastAnswerCorrect == true
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                                  color: _lastAnswerCorrect == true
                                      ? AppColors.profit
                                      : AppColors.loss,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _lastAnswerCorrect == true
                                      ? 'Correct Analysis!'
                                      : 'Incorrect Analysis',
                                  style: TextStyle(
                                    color: _lastAnswerCorrect == true
                                        ? AppColors.profit
                                        : AppColors.loss,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_questions[_currentIndex].explanation,
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        onPressed: _nextQuestion,
                        child: const Text('Next Headline',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildResultsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_outlined,
                size: 64, color: AppColors.discipline),
            const SizedBox(height: 16),
            const Text('Quiz Completed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('You scored $_score / ${_questions.length}',
                style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'Great job practicing critical news evaluation! Always verify sources before acting on market rumors.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetQuiz,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
