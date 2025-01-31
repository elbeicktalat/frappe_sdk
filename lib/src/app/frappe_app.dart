import 'package:frappe_sdk/src/utils/token_type.dart';

class FrappeApp {
  const FrappeApp({
    required this.url,
    required this.name,
    this.useToken = true,
    this.headers = const <String, String>{},
    this.token,
    this.tokenType = TokenType.token,
  });

  final Uri url;
  final String name;
  final Map<String, String> headers;
  final bool useToken;
  final String? token;
  final TokenType tokenType;
}
