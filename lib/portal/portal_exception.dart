class PortalException implements Exception {
  final String message;
  final int statusCode;

  PortalException({required this.message, required this.statusCode});

  @override
  String toString() {
    return message;
  }
}
