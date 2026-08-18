import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'coach_controller.dart';
import '../domain/coach_state.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(coachControllerProvider);

    return AppScaffold(
      showBackButton: false,
      title: 'AI Coach',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            onPressed: () {
              ref.read(coachControllerProvider.notifier).clearHistory();
            },
          ),
          const SizedBox(width: 8),
          const AIAvatar(size: 32),
        ],
      ),
      body: asyncState.when(
        data: (state) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          return _buildChat(context, state);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
        error: (error, stack) => EmptyState(
          icon: Icons.error_outline,
          title: 'Coach is unavailable',
          description: error.toString(),
        ),
      ),
    );
  }

  Widget _buildChat(BuildContext context, CoachState state) {
    return Column(
      children: [
        Expanded(
          child: state.messages.isEmpty && !state.isTyping
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.forum_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Ask me anything about trading!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildExampleChip('How do I manage risk?'),
                            _buildExampleChip('What is a stop loss?'),
                            _buildExampleChip('Explain leverage.'),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: state.messages.length + (state.isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.messages.length && state.isTyping) {
                return const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: ThinkingIndicator(),
                  ),
                );
              }
              final message = state.messages[index];
              return CoachBubble(
                message: message.text,
                isUser: message.isUser,
              );
            },
          ),
        ),
        if (state.error != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.errorRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(coachControllerProvider.notifier).retryLastMessage();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        _buildInputArea(context, state),
      ],
    );
  }

  Widget _buildExampleChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        ref.read(coachControllerProvider.notifier).sendMessage(text);
      },
    );
  }

  Widget _buildInputArea(BuildContext context, CoachState state) {
    final theme = Theme.of(context);
    final bg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final inputFill = theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface;
    final primary = theme.colorScheme.primary;
    final divider = theme.dividerColor;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: !state.isTyping,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Message AI Coach...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                  borderSide: BorderSide(color: divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                  borderSide: BorderSide(color: divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                  borderSide: BorderSide(color: primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                filled: true,
                fillColor: inputFill,
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  ref.read(coachControllerProvider.notifier).sendMessage(text.trim());
                  _textController.clear();
                }
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: state.isTyping
                  ? null
                  : () {
                      if (_textController.text.trim().isNotEmpty) {
                        ref.read(coachControllerProvider.notifier).sendMessage(_textController.text.trim());
                        _textController.clear();
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}
