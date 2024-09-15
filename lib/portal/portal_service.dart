import 'dart:async';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:dart_conversion/dart_conversion.dart';
import 'package:portal/interceptor/interceptor_exception.dart';
import 'package:portal/portal.dart';
import 'package:portal/portal/gateway_service.dart';
import 'package:portal/portal/portal_collector.dart';

PortalService get portalService => PortalService();

FutureOr oneTimerPortal<T>(String path, AnonymousPortal callback) async {
  PortalService()._anonymousPortalMap[path] ??= [];
  PortalService()._anonymousPortalMap[path]!.add(((T data) async {
        await callback(data);
        PortalService()._anonymousPortalMap[path]!.remove(callback);
      }) as AnonymousPortal<dynamic>);
}

typedef AnonymousPortal<T> = FutureOr Function(T data);

typedef NullableString = String?;

class PortalService {
  static PortalService? _instance;
  final Map<String, PortalMirror> _portalMap = {};
  final Map<String, List<AnonymousPortal<dynamic>>> _anonymousPortalMap = {};

  /// Factory constructor for creating or retrieving a singleton instance of [PortalService].
  factory PortalService() {
    _instance ??= PortalService._internal();
    return _instance!;
  }

  PortalService._internal();

  Future<HttpRequest> callGateway(
    String fullPath,
    HttpRequest request,
  ) async {
    try {
      final gatewayMirror = gatewayMirrorUsingFullPath(fullPath);
      try {
        final canPass = await MiddlewareService()
            .preHandle(request, gatewayMirror.interceptors);
        if (!canPass) {
          request.response.statusCode = HttpStatus.unprocessableEntity;
          return request;
        }
      } on IntercetporException catch (e) {
        request.response.statusCode = e.statusCode;
        request.response.write(e.message);
        return request;
      } catch (e) {
        print(e);
        request.response.statusCode = HttpStatus.internalServerError;
        return request;
      }
      if (gatewayMirror.isGet()) {
        print(request.method);
        if (request.method != "GET") {
          request.response.statusCode = HttpStatus.methodNotAllowed;
          return request;
        }
        print("is get");
        return await handleGet(request, gatewayMirror, fullPath);
      } else if (gatewayMirror.isPost()) {
        if (request.method != "POST") {
          request.response.statusCode = HttpStatus.methodNotAllowed;
          return request;
        }
        print("is post");
        return await handlePost(request, gatewayMirror);
      }

      request.response.statusCode = HttpStatus.notFound;
      return request;
    } on PortalException catch (e, s) {
      request.response.statusCode = e.statusCode;
      request.response.write("Error: not found.");
      return request;
    }
  }

  dynamic callMethod(AnnotatedMethod m, Map<String, dynamic> map) async {
    final expectedData = ConversionService.mapToObject(map);

    return await (m.partOf.invoke(m.method.simpleName, [expectedData])
        as FutureOr);
  }

  /// Invokes a method on a portal using a map as the argument.
  ///
  /// This method dynamically invokes a portal method identified by an [AnnotatedMethod]
  /// instance, passing in arguments constructed from a map. This is particularly useful
  /// for invoking methods based on request data.
  ///
  /// Parameters:
  ///   - [m]: The annotated method to invoke.
  ///   - [map]: The map containing the arguments to pass to the method.
  ///
  /// Returns:
  ///   The result of invoking the method.
  dynamic callMethodFromMap(AnnotatedMethod m, Map<String, dynamic> map) async {
    final expectedData = ConversionService.mapToObject(map);

    return await (m.partOf.invoke(m.method.simpleName, [expectedData])
        as FutureOr);
  }

  /// Finds an annotated method within a portal based on the full request path.
  ///
  /// This method locates a method within a portal that matches a specific request path.
  /// It uses annotations to find methods that are designated to handle certain paths.
  ///
  /// Type Parameters:
  ///   - [AnnotatedWith]: The type of annotation to look for, indicating the request type.
  ///
  /// Parameters:
  ///   - [fullPath]: The full path of the request.
  ///
  /// Returns:
  ///   An [AnnotatedMethod] instance representing the method to handle the request, or null
  ///   if no matching method is found.
  GatewayMirror gatewayMirrorUsingFullPath(String fullPath) {
    PortalMirror? portal = _portalByFullPath(fullPath);

    print(portal);
    if (portal == null) {
      throw PortalException(
          message: "No Portal registered with path: $fullPath",
          statusCode: 404);
    }
    var mPath = methodPath(fullPath);
    print("Method path: $mPath");
    print("portal has gateways: ${portal.gateways.length}");
    for (var element in portal.gateways) {
      print(element.getPath);
    }
    final GatewayMirror gateway = portal.gateways.firstWhere(
      (element) => element.getPath == mPath,
      orElse: () => throw Exception("No Gateway registered with path: $mPath"),
    );

    return gateway;
  }

  Future<HttpRequest> handleGet(
      HttpRequest request, GatewayMirror gatewayMirror, String fullPath) async {
    print("Handling get request for $fullPath with gateway $gatewayMirror "
        "${request.uri.queryParameters} ${gatewayMirror.methodArgumentType()}");
    final argType = gatewayMirror.methodArgumentType();
    print("argType: $argType");
    late final dynamic argInstance;

    try {
      argInstance = argType != null
          ? await ConversionService.requestToObject(request,
              type: gatewayMirror.methodArgumentType()?.reflectedType)
          : null;
    } on ConversionException catch (e) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write("Data invalid.");
      print(e.message);
      return request;
    }
    print("argInstance $argInstance");

    final String? methodParamName = gatewayMirror.methodMirror.parameters
        .where(
          (element) => element.metadata.isEmpty,
        )
        .firstOrNull
        ?.name;
    dynamic response;
    try {
      final dynamic response0 = await methodService.invokeAsync(
          holderMirror: gatewayMirror.portalInstanceMirror,
          methodMirror: gatewayMirror.methodMirror,
          argumentsMap: argType != null
              ? {
                  methodParamName!:
                      await ConversionService.requestToRequestDataMap(request)
                }
              : {},
          onParameterAnotation: [
            OnParameterAnotation<HeaderMapping>(
              <NullableString>(key, value, headerMapping) {
                final value = request.headers.value(headerMapping.key);
                print(value);
                return value as NullableString;
              },
            )
          ]);
      print("Result: $response0");

      response = response0;
    } on PortalException catch (e, s) {
      print("Error: $e"
          "Stacktrace: $s");
      request.response.statusCode = e.statusCode;
      response = e.message;
    } catch (e, s) {
      print("Error: $e"
          "Stacktrace: $s");
      request.response.statusCode = HttpStatus.internalServerError;
    }

    request.response.write(ConversionService.encodeJSON(response));
    await MiddlewareService()
        .postHandle(request, gatewayMirror.interceptors, argInstance, response);
    return request;
  }

  Future<HttpRequest> handlePost(
      HttpRequest request, GatewayMirror gatewayMirror) async {
    dynamic result;
    final String? methodParamName = gatewayMirror.methodMirror.parameters
        .where(
          (element) => element.metadata.isEmpty,
        )
        .firstOrNull
        ?.name;
    final argType = gatewayMirror.methodArgumentType();

    late final dynamic argInstance;
    try {
      argInstance = argType != null
          ? await ConversionService.requestToObject(request,
              type: gatewayMirror.methodArgumentType()?.reflectedType)
          : null;
      print("argInstance $argInstance");
    } on ConversionException catch (e) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write("Data invalid.");
      print(e.message);

      return request;
    }
    final argMap = ConversionService.objectToMap(argInstance);
    try {
      final result0 = await methodService.invokeAsync(
          holderMirror: gatewayMirror.portalInstanceMirror,
          methodMirror: gatewayMirror.methodMirror,
          argumentsMap: argType != null ? {methodParamName!: argMap} : {},
          onParameterAnotation: [
            OnParameterAnotation<HeaderMapping>(
              <NullableString>(key, value, headerMapping) {
                final value = request.headers.value(headerMapping.key);
                print(value);
                return value as NullableString;
              },
            )
          ]);

      result = result0;
      print("Result: $result0");
      request.response.write(ConversionService.encodeJSON(result));
    } on PortalException catch (e, s) {
      request.response.statusCode = e.statusCode;
      print("Error: $e"
          "Stacktrace: $s");
      request.response.write(e.message);
    } catch (e, s) {
      print("Error: $e"
          "Stacktrace: $s");
      request.response.statusCode = HttpStatus.internalServerError;
    }

    await MiddlewareService()
        .postHandle(request, gatewayMirror.interceptors, argInstance, result);
    return request;
  }

  /// Extracts the method path from the full path of a request.
  ///
  /// This method separates the portal path from the full path and returns the remaining
  /// part, which corresponds to the method path within the portal.
  ///
  /// Parameters:
  ///   - [fullPath]: The full path of the request.
  ///
  /// Returns:
  ///   The method path extracted from the full path.
  String methodPath(String fullPath) {
    var portalPath = _pathByFullPath(fullPath);
    var methodPath = fullPath.substring(portalPath.length);

    return methodPath;
  }

  registerPortal(dynamic portal) {
    final path = metadata(type: portal.runtimeType).first.getPath;
    _portalMap[path] = portal;
  }

  /// Registers a portal with the service.
  ///
  /// This method takes a portal instance, retrieves its path using the [Portal] annotation,
  /// and maps the path to the portal in the [_portalMap]. This allows for the retrieval of
  /// portal instances based on their path.
  ///
  /// Parameters:
  ///   - [portal]: The portal instance to register.
  registerPortals() {
    _portalMap.clear();
    _portalMap.addAll(Map.fromEntries(PortalCollector.collect().map(
      (e) {
        print("registering portal: ${e.portal.getPath}");
        print("gateway: ${e.gateways}");
        return MapEntry(e.portal.getPath, e);
      },
    )));

    print("registered portals: $_portalMap");
  }

  /// Extracts the portal path from the full path of a request.
  ///
  /// This method processes the full path to isolate and return the path segment that corresponds
  /// to the portal. It is used internally to map requests to their respective portals.
  ///
  /// Parameters:
  ///   - [rawFullPath]: The full path of the request.
  ///
  /// Returns:
  ///   The extracted path segment corresponding to the portal.
  String _pathByFullPath(String rawFullPath) {
    var path = rawFullPath;
    if (path.characters.first == "/") {
      path = "/";
      for (int i = 1; i < rawFullPath.characters.length; i++) {
        var char = rawFullPath.characters.elementAt(i);
        if (char == "/") {
          break;
        }
        path += char;
      }
    }
    return path;
  }

  /// Retrieves a portal instance based on the full path of a request.
  ///
  /// This method parses the full path to extract the portal path, then retrieves the portal
  /// instance associated with that path from the [_portalMap].
  ///
  /// Parameters:
  ///   - [fullPath]: The full path of the request.
  ///
  /// Returns:
  ///   The portal instance associated with the extracted path.
  PortalMirror? _portalByFullPath(String fullPath) {
    print(_portalMap);
    dynamic portal;
    try {
      portal = _portalMap[_pathByFullPath(fullPath)];
      if (portal == null) {
        throw PortalException(
            message: "No Portal registered with path: $fullPath",
            statusCode: 404);
      }
    } catch (e) {
      print("Error: $e");
    }
    return portal;
  }
}
