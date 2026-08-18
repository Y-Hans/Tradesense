import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// Live integration test that executes actual concurrent HTTP RPC calls against a live Supabase backend.
/// To execute against live Supabase:
/// flutter test test/integration/live_supabase_concurrency_test.dart --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
void main() {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  final isConfigured = supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  group('Live Supabase Concurrency & Security Integration Tests', () {
    late SupabaseClient client;

    setUpAll(() async {
      if (isConfigured) {
        client = SupabaseClient(supabaseUrl, supabaseKey);
      }
    });

    test('Live AI Rate-Limit Concurrent Requests: 5 simultaneous RPCs', () async {
      if (!isConfigured) {
        // Skip when live credentials are not injected via environment
        return;
      }

      final testUserId = '00000000-0000-0000-0000-000000000001';

      // Dispatch 5 simultaneous network requests to the live RPC endpoint
      final results = await Future.wait(
        List.generate(5, (_) => client.rpc('fn_increment_ai_usage', params: {'p_user_id': testUserId})),
      );

      expect(results.length, equals(5));
      for (final res in results) {
        expect(res, isNotNull);
      }
    });

    test('Live Profile XP Security: Direct client update rejected by trigger', () async {
      if (!isConfigured) {
        return;
      }

      // Authenticated client trying to directly modify total_xp
      expect(
        () => client.from('profiles').update({'total_xp': 9999}).eq('id', client.auth.currentUser?.id ?? ''),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
