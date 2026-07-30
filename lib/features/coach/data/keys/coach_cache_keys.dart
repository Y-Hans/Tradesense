import '../../../../shared/models/coach_request.dart';

/// Centralized cache keys helper for AI Coach requests.
class CoachCacheKeys {
  CoachCacheKeys._();

  /// Generates a deterministic cache key derived from normalized [CoachRequest] content.
  ///
  /// Excludes metadata, timestamps, IDs (userId, tradeId), or non-functional fields
  /// that do not influence the generated AI coaching output.
  static String forRequest(CoachRequest request) {
    final tradeMap = _normalizeMap(request.tradeContext);
    final portfolioMap = _normalizeMap(request.portfolioContext);
    final marketMap = _normalizeMap(request.marketContext);

    final payload = <String, dynamic>{
      'trade': tradeMap,
      'portfolio': portfolioMap,
      'market': marketMap,
      'risk_score': request.riskScore,
      'discipline_score': request.disciplineScore,
    };

    final canonicalString = _toCanonicalString(payload);
    return 'coach_req_$canonicalString';
  }

  static Map<String, dynamic> _normalizeMap(Map<String, dynamic> source) {
    final result = <String, dynamic>{};
    final sortedKeys = source.keys.toList()..sort();
    for (final key in sortedKeys) {
      final value = source[key];
      if (value is Map<String, dynamic>) {
        result[key] = _normalizeMap(value);
      } else if (value is List) {
        final listCopy = List<dynamic>.from(value);
        listCopy.sort((a, b) => a.toString().compareTo(b.toString()));
        result[key] = listCopy;
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  static String _toCanonicalString(Object? obj) {
    if (obj is Map<String, dynamic>) {
      final entries = obj.entries.map((e) => '"${e.key}":${_toCanonicalString(e.value)}');
      return '{${entries.join(',')}}';
    } else if (obj is List) {
      final items = obj.map(_toCanonicalString);
      return '[${items.join(',')}]';
    } else if (obj is String) {
      return '"$obj"';
    } else {
      return obj.toString();
    }
  }
}
