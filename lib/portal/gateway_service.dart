import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:dart_conversion/dart_conversion.dart';
import 'package:portal/my_logger.dart';
import 'package:portal/portal.dart';

class GatewayService {
  Future<MethodParameters> generateGatewayArguments(
      {required HttpRequest request,
      required GatewayMirror gatewayMirror}) async {
    final ut8String = await utf8.decodeStream(request);
    final arguments = <dynamic>[];
    final namedArguments = <String, dynamic>{};
    final params = gatewayMirror.methodMirror.parameters;
    for (final param in params) {
      if (param.isNamed) {
        myLogger.d("Named parameter: ${param.name}", header: "GatewayService");
        if (param.isHeaderMapping) {
          myLogger.d("Found HeaderMapping --> ${param.name}",
              header: "GatewayService");
          namedArguments[param.name] = request.headers[param.name];
          continue;
        }
        if (param.isQueryMapping) {
          myLogger.d("Found QueryMapping --> ${param.name}",
              header: "GatewayService");
          namedArguments[param.name] = ConversionService.convert(
              type: param.type.reflectedType,
              value: request.uri.queryParameters[param.name]);
          continue;
        }
        if (param.isQueriesMapping) {
          myLogger.d("Found QueriesMapping --> ${param.name}",
              header: "GatewayService");
          namedArguments[param.name] = ConversionService.mapToObject(
              request.uri.queryParameters,
              type: param.type.reflectedType);
          continue;
        }
        myLogger.d(
            "No Mapping found for named parameter \"${param.name}\". Interpreting as @QueryiesMapping. See documentation for details.",
            header: "GatewayService");
        if (gatewayMirror.isGet()) {
          namedArguments[param.name] = ConversionService.mapToObject(
            request.uri.queryParameters,
            type: param.type.reflectedType,
          );
        } else if (gatewayMirror.isPost()) {
          namedArguments[param.name] = ConversionService.mapToObject(
              jsonDecode(ut8String),
              type: param.type.reflectedType);
        }
      } else {
        myLogger.d("Named parameter: ${param.name}", header: "GatewayService");
        if (param.isHeaderMapping) {
          myLogger.d("Found HeaderMapping --> ${param.name}",
              header: "GatewayService");
          arguments.add(request.headers[param.name]);
          continue;
        }
        if (param.isQueryMapping) {
          myLogger.d("Found QueryMapping --> ${param.name}",
              header: "GatewayService");
          arguments.add(ConversionService.convert(
              type: param.type.reflectedType,
              value: request.uri.queryParameters[param.name]));
          continue;
        }
        if (param.isQueriesMapping) {
          myLogger.d("Found QueriesMapping --> ${param.name}",
              header: "GatewayService");
          arguments.add(ConversionService.mapToObject(
              request.uri.queryParameters,
              type: param.type.reflectedType));
          continue;
        }

        if (gatewayMirror.isGet()) {
          myLogger.d(
              "No Mapping found for named parameter \"${param.name}\". Interpreting as @QueryiesMapping. See documentation for details.",
              header: "GatewayService");
          arguments.add(ConversionService.mapToObject(
            request.uri.queryParameters,
            type: param.type.reflectedType,
          ));
        } else if (gatewayMirror.isPost()) {
          myLogger.d(
              "Using requestToObject to mapToObject body to object for parameter \"${param.name}\". See documentation for details.",
              header: "GatewayService");
          arguments.add(ConversionService.mapToObject(jsonDecode(ut8String),
              type: param.type.reflectedType));
        }
      }
    }

    return MethodParameters(arguments, namedArguments);
  }
}

extension ParameterName on ParameterMirror {
  bool get isHeaderMapping =>
      this.metadata.any((element) => element is HeaderMapping);

  bool get isQueriesMapping =>
      this.metadata.any((element) => element is QueriesMapping);

  bool get isQueryMapping =>
      this.metadata.any((element) => element is QueryMapping);

  String get name => MirrorSystem.getName(simpleName);
}
