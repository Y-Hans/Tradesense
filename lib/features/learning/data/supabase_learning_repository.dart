import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/supabase_provider.dart';

part 'supabase_learning_repository.g.dart';

class SupabaseLearningRepository {
  final SupabaseClient _supabase;

  SupabaseLearningRepository(this._supabase);

  Future<int> getTotalXp() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    final response = await _supabase
        .from('profiles')
        .select('total_xp')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return 0;
    return response['total_xp'] as int? ?? 0;
  }

  Future<Set<String>> getCompletedMissions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};

    final response = await _supabase
        .from('mission_progress')
        .select('mission_id')
        .eq('user_id', user.id);

    final data = response as List<dynamic>;
    return data.map((e) => e['mission_id'] as String).toSet();
  }
}

@riverpod
SupabaseLearningRepository learningRepository(LearningRepositoryRef ref) {
  return SupabaseLearningRepository(ref.watch(supabaseClientProvider));
}
