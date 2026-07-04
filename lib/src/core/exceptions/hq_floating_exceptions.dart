/// Base exception class for all HQFloating related errors.
class HQFloatingException implements Exception {
  final String message;

  HQFloatingException(this.message);

  @override
  String toString() => 'HQFloatingException: $message';
}

/// Thrown when the application lacks the system overlay permission.
class HQFloatingPermissionException extends HQFloatingException {
  HQFloatingPermissionException(super.message);

  @override
  String toString() => 'HQFloatingPermissionException: $message';
}

/// Thrown when an overlay window operation fails.
class HQFloatingWindowException extends HQFloatingException {
  HQFloatingWindowException(super.message);

  @override
  String toString() => 'HQFloatingWindowException: $message';
}
