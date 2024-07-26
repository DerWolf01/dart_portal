class IntercetporException implements Exception {
  final String message;
  final int statusCode;

  IntercetporException(this.message, this.statusCode);
}
