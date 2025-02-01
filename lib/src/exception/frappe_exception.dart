// ignore_for_file: lines_longer_than_80_chars

/// The Frappe exception.
abstract class FrappeException implements Exception {
  /// Creates a new [FrappeException].
  FrappeException(
    this.statusCode, {
    required this.message,
  });

  /// The message of the exception.
  final String message;

  /// The status code of the exception.
  final int statusCode;

  @override
  String toString() {
    return 'FrappeException{message: $message}';
  }
}

/// An exception thrown when a document is not found.
class FrappeDocNotFoundException extends FrappeException {
  /// Creates a new [FrappeDocNotFoundException].
  FrappeDocNotFoundException(
    super.statusCode,
  ) : super(message: _badResponseExceptionMessage(statusCode));

  @override
  String toString() {
    return 'FrappeDocNotFoundException: \n$message';
  }
}

/// An exception thrown when request is not authorized.
class FrappeUnauthorizedException extends FrappeException {
  /// Creates a new [FrappeUnauthorizedException].
  FrappeUnauthorizedException(
    super.statusCode,
  ) : super(message: _badResponseExceptionMessage(statusCode));

  @override
  String toString() {
    return 'FrappeUnauthorizedException: \n$message';
  }
}

String _badResponseExceptionMessage(int statusCode) {
  final String message;
  if (statusCode >= 100 && statusCode < 200) {
    message =
        'This is an informational response - the request was received, continuing processing';
  } else if (statusCode >= 200 && statusCode < 300) {
    message = 'The request was successfully received, understood, and accepted';
  } else if (statusCode >= 300 && statusCode < 400) {
    message =
        'Redirection: further action needs to be taken in order to complete the request';
  } else if (statusCode >= 400 && statusCode < 500) {
    message =
        'Client error - the request contains bad syntax or cannot be fulfilled';
  } else if (statusCode >= 500 && statusCode < 600) {
    message =
        'Server error - the server failed to fulfil an apparently valid request';
  } else {
    message =
        'A response with a status code that is not within the range of inclusive 100 to exclusive 600 '
        "is a non-standard response, possibly due to the server's software";
  }

  final StringBuffer buffer = StringBuffer()
    ..writeln(
      'This exception was thrown because the response has a status code of $statusCode',
    )
    ..writeln(
      'The status code of $statusCode has the following meaning: "$message"',
    )
    ..writeln(
      'Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/$statusCode',
    )
    ..writeln(
      'In order to resolve this exception you typically have either to verify '
      'and fix your request code or you have to fix the server code.',
    );

  return buffer.toString();
}
