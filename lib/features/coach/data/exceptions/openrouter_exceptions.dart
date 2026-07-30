/// Base exception thrown by OpenRouter AI Provider operations.
class OpenRouterException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errorBody;

  const OpenRouterException(
    this.message, {
    this.statusCode,
    this.errorBody,
  });

  @override
  String toString() =>
      'OpenRouterException: $message${statusCode != null ? ' (Status Code: $statusCode)' : ''}';
}

/// Thrown when an OpenRouter network request times out.
class OpenRouterTimeoutException extends OpenRouterException {
  const OpenRouterTimeoutException(
    super.message, {
    super.statusCode,
    super.errorBody,
  });

  @override
  String toString() => 'OpenRouterTimeoutException: $message';
}

/// Thrown when an OpenRouter response fails validation or structural invariant checks.
class OpenRouterValidationException extends OpenRouterException {
  const OpenRouterValidationException(
    super.message, {
    super.statusCode,
    super.errorBody,
  });

  @override
  String toString() => 'OpenRouterValidationException: $message';
}

/// Thrown when an OpenRouter response JSON is malformed or unparseable.
class OpenRouterFormatException extends OpenRouterException {
  const OpenRouterFormatException(
    super.message, {
    super.statusCode,
    super.errorBody,
  });

  @override
  String toString() => 'OpenRouterFormatException: $message';
}
