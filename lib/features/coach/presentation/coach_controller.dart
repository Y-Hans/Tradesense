import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/coach_state.dart';
import '../data/coach_repository.dart';

part 'coach_controller.g.dart';

@riverpod
class CoachController extends _$CoachController {
  @override
  FutureOr<CoachState> build() async {
    final repo = ref.read(coachRepositoryProvider);
    final history = await repo.fetchHistory();
    return CoachState(
      isLoading: false,
      messages: history,
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    final repo = ref.read(coachRepositoryProvider);
    
    // Add user message optimistically
    final userMsg = await repo.sendMessage(text);
    state = AsyncValue.data(
      state.requireValue.copyWith(
        messages: [...state.requireValue.messages, userMsg],
        isTyping: true,
      ),
    );

    try {
      final response = await repo.getCoachResponse(text);
      state = AsyncValue.data(
        state.requireValue.copyWith(
          messages: [...state.requireValue.messages, response],
          isTyping: false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        state.requireValue.copyWith(
          isTyping: false,
          error: 'Failed to get response',
        ),
      );
    }
  }
}
