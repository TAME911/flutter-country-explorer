// lib/services/api_exception.dart
//
// Custom exception class — required by assignment Section 4.5.
// Thrown by _checkResponse() whenever the server returns a non-200 status.

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
