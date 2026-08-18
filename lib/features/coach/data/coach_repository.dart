import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../domain/coach_state.dart';
import '../../../core/providers/supabase_provider.dart';

part 'coach_repository.g.dart';

class CoachRepository {
  final SupabaseClient _supabase;
  final _uuid = const Uuid();
  final List<ChatMessage> _history = [];

  CoachRepository(this._supabase);

  Future<List<ChatMessage>> fetchHistory() async {
    if (_history.isNotEmpty) return List.from(_history);

    try {
      // Get the latest conversation for the user
      final user = _supabase.auth.currentUser;
      if (user == null) return _history;

      final convResponse = await _supabase
          .from('coach_conversations')
          .select('id')
          .eq('user_id', user.id)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (convResponse != null) {
        _conversationId = convResponse['id'] as String;
        
        final messagesResponse = await _supabase
            .from('coach_messages')
            .select('*')
            .eq('conversation_id', _conversationId!)
            .order('created_at', ascending: true);
            
        final List<dynamic> data = messagesResponse;
        for (var msg in data) {
          _history.add(ChatMessage(
            id: msg['id'] as String,
            text: msg['content'] as String,
            isUser: msg['role'] == 'user',
            timestamp: DateTime.parse(msg['created_at'] as String),
          ));
        }
      }
    } catch (e) {
      // fallback to empty history
    }

    if (_history.isEmpty) {
      _history.add(ChatMessage(
        id: _uuid.v4(),
        text:
            'Hello Trader. Welcome to TradeSense AI Coach. Ready to review your trades or discuss strategies?',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ));
    }
    return List.from(_history);
  }

  void _addToHistory(ChatMessage message) {
    _history.add(message);
    if (_history.length > 100) {
      _history.removeRange(0, _history.length - 100);
    }
  }

  Future<ChatMessage> sendMessage(String text) async {
    final message = ChatMessage(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _addToHistory(message);
    return message;
  }

  String? _conversationId;

  Future<ChatMessage> getCoachResponse(String userText) async {
    try {
      final response = await _supabase.functions.invoke(
        'coach_chat',
        body: {
          'current_message': userText,
          if (_conversationId != null) 'conversation_id': _conversationId,
        },
      );

      if (response.status != 200) {
        final errDetails = response.data is Map ? response.data['error'] : response.data;
        throw FunctionException(
          status: response.status,
          details: errDetails ?? 'Request failed with status ${response.status}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final responseText = data['text'] as String? ?? 'No response text available.';
      if (data.containsKey('conversation_id')) {
        _conversationId = data['conversation_id'] as String;
      }

      final message = ChatMessage(
        id: _uuid.v4(),
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _addToHistory(message);
      return message;
    } on FunctionException catch (e) {
      final status = e.status ?? 500;
      if (status == 429) {
        throw Exception('Daily message limit reached. Try again tomorrow.');
      } else if (status == 403) {
        throw Exception('Conversation access denied.');
      }
      throw Exception('Coach is unavailable: ${e.details?.toString() ?? "Service error"}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to connect to Coach: ${e.toString()}');
    }
  }

  void clearHistory() {
    _history.clear();
    _conversationId = null;
    _addToHistory(ChatMessage(
      id: _uuid.v4(),
      text:
          'Hello Trader. Welcome to TradeSense AI Coach. Ready to review your trades or discuss strategies?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  List<ChatMessage> getHistorySync() => List.unmodifiable(_history);
}

@riverpod
CoachRepository coachRepository(CoachRepositoryRef ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return CoachRepository(supabase);
}
