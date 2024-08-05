import 'dart:io';
import 'dart:mirrors';

import 'package:portal/portal.dart';

class GatewayService {
  generateGatewayArguments(
      {required HttpRequest request, required GatewayMirror gatewayMirror}) {
    final arguments = <dynamic>[];
    final namedArguments = <String, dynamic>{};
    final params = gatewayMirror.methodMirror.parameters;
    for (final param in params) {
      if (param.isNamed) {
        if (param.metadata.any(
              (element) => element is HeaderMapping,
        )) {
          namedArguments[param.name] = request.headers[param.name];
          continue;
        }
        namedArguments[param.name] = request.uri.queryParameters[param.name];
      } else {
        if (param.metadata.any(
              (element) => element is HeaderMapping,
        )) {
          arguments.add(request.headers[param.name]);
          continue;
        }
        final value = request.uri.queryParameters[param.name];
        arguments.add(value);
      }
    }
  }
}

extension ParameterName on ParameterMirror {
  String get name => MirrorSystem.getName(simpleName);
}
