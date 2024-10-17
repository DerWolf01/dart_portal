import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:dart_conversion/dart_conversion.dart';
import 'package:portal/my_logger.dart';
import 'package:portal/portal.dart';

class GatewayService {
  Future<MethodParameters?> generateGatewayArguments(
      {required HttpRequest request,
      required GatewayMirror gatewayMirror}) async {
    try {
      final contentType = request.headers.contentType ?? ContentType.json;
      myLogger.i("Content-Type: $contentType", header: "GatewayService");
      final ut8String = await utf8.decodeStream(request);
      final arguments = <dynamic>[];
      final namedArguments = <String, dynamic>{};
      final params = gatewayMirror.methodMirror.parameters;
      for (final param in params) {
        if (param.isNamed) {
          myLogger.i("Named parameter: ${param.name}",
              header: "GatewayService");
          if (param.isHeaderMapping) {
            myLogger.i("Found HeaderMapping --> ${param.name}",
                header: "GatewayService");

            final headerMapping = param.metadata
                .where((element) => element.reflectee is HeaderMapping)
                .first
                .reflectee as HeaderMapping;
            final key = headerMapping.key;
            myLogger.i("HeaderMapping key -->  \"$key\"",
                header: "GatewayService");
            namedArguments[param.name] = request.headers.value(key);
            continue;
          }
          if (param.isQueryMapping) {
            myLogger.i("Found QueryMapping --> ${param.name}",
                header: "GatewayService");

            final convertedValue = ConversionService.convert(
                type: param.type.reflectedType,
                value: request.uri.queryParameters[param.name]);
            myLogger.i("Converted $ut8String --> $convertedValue",
                header: "GatewayService");
            namedArguments[param.name] = convertedValue;
            continue;
          }
          if (param.isQueriesMapping) {
            myLogger.i("Found QueriesMapping --> ${param.name}",
                header: "GatewayService");
            final convertedValue = ConversionService.convert(
                value: request.uri.queryParameters,
                type: param.type.reflectedType);
            myLogger.i("Converted $ut8String --> $convertedValue",
                header: "GatewayService");
            namedArguments[param.name] = convertedValue;
            continue;
          }
          myLogger.i(
              "No Mapping found for named parameter \"${param.name}\". Interpreting as @QueryiesMapping. See documentation for details.",
              header: "GatewayService");
          if (gatewayMirror.isGet()) {
            final convertedValue = ConversionService.convert(
              value: request.uri.queryParameters,
              type: param.type.reflectedType,
            );
            myLogger.i("Converted $ut8String --> $convertedValue",
                header: "GatewayService");
            namedArguments[param.name] = convertedValue;
          } else if (gatewayMirror.isPost()) {
            late final dynamic convertedValue;
            if (contentType == ContentType.json ||
                contentType.subType == "json") {
              final json = jsonDecode(ut8String);
              myLogger.i(
                  "Converting $json to object of type ${param.type.reflectedType}",
                  header: "GatewayService");
              convertedValue = ConversionService.mapToObject(json,
                  type: param.type.reflectedType);

              myLogger.i(
                  "Converted \"$ut8String\" to value \"$convertedValue\" of type ${convertedValue.runtimeType}",
                  header: "GatewayService");
            } else {
              myLogger.i(
                  "Converting $ut8String to object of type ${param.type.reflectedType}",
                  header: "GatewayService");
              convertedValue = ConversionService.convert(
                  value: ut8String, type: param.type.reflectedType);
              myLogger.i(
                  "Converted \"$ut8String\" to value \"$convertedValue\" of type ${convertedValue.runtimeType}",
                  header: "GatewayService");
            }

            namedArguments[param.name] = convertedValue;
          }
        } else {
          myLogger.i("Named parameter: ${param.name}",
              header: "GatewayService");
          if (param.isHeaderMapping) {
            myLogger.i("Found HeaderMapping --> ${param.name}",
                header: "GatewayService");

            final headerMapping = param.metadata
                .where((element) => element.reflectee is HeaderMapping)
                .first
                .reflectee as HeaderMapping;
            final key = headerMapping.key;
            myLogger.i("HeaderMapping key -->  \"$key\"",
                header: "GatewayService");
            arguments.add(request.headers.value(key));
            continue;
          }
          if (param.isQueryMapping) {
            myLogger.i("Found QueryMapping --> ${param.name}",
                header: "GatewayService");
            arguments.add(ConversionService.convert(
                type: param.type.reflectedType,
                value: request.uri.queryParameters[param.name]));
            continue;
          }
          if (param.isQueriesMapping) {
            myLogger.i("Found QueriesMapping --> ${param.name}",
                header: "GatewayService");

            final convertedValue = ConversionService.convert(
                value: request.uri.queryParameters,
                type: param.type.reflectedType);
            myLogger.i("Converted $ut8String --> $convertedValue",
                header: "GatewayService");
            arguments.add(convertedValue);
            continue;
          }

          if (gatewayMirror.isGet()) {
            myLogger.i(
                "No Mapping found for named parameter \"${param.name}\". Interpreting as @QueryiesMapping. See documentation for details.",
                header: "GatewayService");

            final convertedValue = ConversionService.convert(
              value: request.uri.queryParameters,
              type: param.type.reflectedType,
            );
            myLogger.i("Converted $ut8String --> $convertedValue",
                header: "GatewayService");
            arguments.add(convertedValue);
          } else if (gatewayMirror.isPost()) {
            late final dynamic convertedValue;

            if (contentType == ContentType.json ||
                contentType.subType == "json") {
              final json = jsonDecode(ut8String);
              myLogger.i(
                  "Converting $json to object of type ${param.type.reflectedType}",
                  header: "GatewayService");
              convertedValue = ConversionService.mapToObject(json,
                  type: param.type.reflectedType);

              myLogger.i(
                  "Converted \"$ut8String\" to value \"$convertedValue\" of type ${convertedValue.runtimeType}",
                  header: "GatewayService");
            } else {
              myLogger.i(
                  "Converting $ut8String to object of type ${param.type.reflectedType}",
                  header: "GatewayService");
              convertedValue = ConversionService.convert(
                  value: ut8String, type: param.type.reflectedType);
              myLogger.i(
                  "Converted \"$ut8String\" to value \"$convertedValue\" of type ${convertedValue.runtimeType}",
                  header: "GatewayService");
            }

            arguments.add(convertedValue);
          }
        }
      }

      return MethodParameters(arguments, namedArguments);
    } catch (e, s) {
      myLogger.e(e, stackTrace: s, header: "GatewayService");
    }
    return null;
  }
}

extension ParameterName on ParameterMirror {
  bool get isHeaderMapping =>
      this.metadata.any((element) => element.reflectee is HeaderMapping);

  bool get isQueriesMapping =>
      this.metadata.any((element) => element.reflectee is QueriesMapping);

  bool get isQueryMapping =>
      this.metadata.any((element) => element.reflectee is QueryMapping);

  String get name => MirrorSystem.getName(simpleName);
}
