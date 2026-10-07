// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:dio/dio.dart';

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

/// An exception thrown when the server answered a request with an error:
/// a `frappe.throw`, a permission error, an unhandled exception, ...
class FrappeServerException extends FrappeException {
  /// Creates a new [FrappeServerException].
  FrappeServerException(
    super.statusCode, {
    this.serverMessage,
    this.excType,
  }) : super(message: serverMessage ?? _badResponseExceptionMessage(statusCode));

  /// Builds the exception from the error response of [e].
  ///
  /// Frappe sends what the user should read in `_server_messages` (what
  /// `frappe.throw`/`frappe.msgprint` said, translated to the request's
  /// language), and the exception class name in `exc_type`.
  factory FrappeServerException.fromResponse(Response<dynamic> response) {
    final int statusCode = response.statusCode ?? 500;
    final dynamic data = response.data;
    final Map<String, dynamic> json = data is Map<String, dynamic>
        ? data
        : data is String
            ? _tryDecode(data)
            : <String, dynamic>{};

    final String? excType = json['exc_type']?.toString();
    final String? message = _serverMessages(json['_server_messages']) ??
        // A raised (not frappe.throw-n) error: its text is only in
        // `exception`. Only trusted on a 4xx: a 5xx is an unhandled error
        // whose text is a technical one (`TypeError: ...`).
        (statusCode >= 400 && statusCode < 500 ? _exceptionText(json['exception']) : null);
    switch (statusCode) {
      case 404:
        return FrappeNotFoundException(statusCode, serverMessage: message, excType: excType);
      case 401:
        return FrappeUnauthorizedException(statusCode, serverMessage: message, excType: excType);
    }
    return FrappeServerException(statusCode, serverMessage: message, excType: excType);
  }

  /// What the server said, ready to show to the user as it is; null when it
  /// said nothing usable (an unhandled exception only has a traceback).
  final String? serverMessage;

  /// The name of the server-side exception class, e.g. `ValidationError`.
  final String? excType;

  @override
  String toString() => serverMessage ?? 'FrappeServerException($statusCode, $excType)';
}

/// An exception thrown when a document is not found.
class FrappeNotFoundException extends FrappeServerException {
  /// Creates a new [FrappeNotFoundException].
  FrappeNotFoundException(
    super.statusCode, {
    super.serverMessage,
    super.excType,
  });
}

/// An exception thrown when request is not authorized.
class FrappeUnauthorizedException extends FrappeServerException {
  /// Creates a new [FrappeUnauthorizedException].
  FrappeUnauthorizedException(
    super.statusCode, {
    super.serverMessage,
    super.excType,
  });
}

/// An exception thrown when the server couldn't be reached at all (no
/// connection, timeout, ...), so there's no answer to show.
class FrappeNetworkException extends FrappeException {
  /// Creates a new [FrappeNetworkException].
  FrappeNetworkException(this.cause) : super(0, message: cause.message ?? cause.type.name);

  /// The underlying error.
  final DioException cause;

  @override
  String toString() => 'FrappeNetworkException: $message';
}

Map<String, dynamic> _tryDecode(String data) {
  try {
    final Object? decoded = jsonDecode(data);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } on FormatException {
    return <String, dynamic>{};
  }
}

const String _newline = '\n';

/// `exception` reads `module.ExceptionClass: message`: the message.
String? _exceptionText(Object? raw) {
  if (raw is! String) return null;
  final int separator = raw.indexOf(': ');
  final String text = (separator == -1 ? '' : raw.substring(separator + 2)).trim();
  return text.isEmpty ? null : text;
}

/// `_server_messages` is a JSON list of JSON objects, each with a `message`
/// that may carry some HTML: their plain texts, one per line.
String? _serverMessages(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  try {
    final Object? entries = jsonDecode(raw);
    if (entries is! List) return null;

    final List<String> messages = <String>[];
    for (final Object? entry in entries) {
      final Object? decoded = entry is String ? jsonDecode(entry) : entry;
      final Object? message = decoded is Map ? decoded['message'] : decoded;
      if (message == null) continue;
      final String text = message
          .toString()
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), _newline)
          .replaceAll(RegExp('<[^>]*>'), '')
          .trim();
      if (text.isNotEmpty) messages.add(text);
    }
    return messages.isEmpty ? null : messages.join(_newline);
  } on FormatException {
    return null;
  }
}

String _badResponseExceptionMessage(int statusCode) {
  final String message;
  if (statusCode >= 100 && statusCode < 200) {
    message = 'This is an informational response - the request was received, continuing processing';
  } else if (statusCode >= 200 && statusCode < 300) {
    message = 'The request was successfully received, understood, and accepted';
  } else if (statusCode >= 300 && statusCode < 400) {
    message = 'Redirection: further action needs to be taken in order to complete the request';
  } else if (statusCode >= 400 && statusCode < 500) {
    message = 'Client error - the request contains bad syntax or cannot be fulfilled';
  } else if (statusCode >= 500 && statusCode < 600) {
    message = 'Server error - the server failed to fulfil an apparently valid request';
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
