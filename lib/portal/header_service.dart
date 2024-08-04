import 'dart:io';

import 'package:portal/portal.dart';
import 'package:portal/portal/header_mapping.dart';

HeaderService get headerService => HeaderService();

class HeaderService {
  static HeaderService? _headerService;

  HeaderService._internal();

  factory HeaderService() => _headerService ??= HeaderService._internal();

  List<dynamic> findMappings(HttpRequest request, GatewayMirror mirror) {
    final mappings = <dynamic>[];
    for (final arg in mirror.methodMirror.parameters) {
      if (arg.metadata.isEmpty) {
        continue;
      }
      final metadata = arg.metadata.first;
      if (metadata is HeaderMapping) {
        final header =
            request.headers[metadata.getField(Symbol("key")) as String];
        mappings.add(header);
      }
    }
    return mappings;
  }
}
