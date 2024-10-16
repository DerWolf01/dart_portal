import 'dart:async';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:dart_conversion/dart_conversion.dart';
import 'package:portal/interceptor/interceptor_exception.dart';
import 'package:portal/my_logger.dart';
import 'package:portal/portal.dart';
import 'package:portal/portal/collection/portal_collection.dart';
import 'package:portal/portal/gateway_service.dart';
import 'package:portal/portal/portal_collector.dart';

PortalService get portalService => PortalService();

FutureOr closePortal<T>(String path, AnonymousPortal callback) async {
  throw UnimplementedError("Not implemented");
}

FutureOr openPortal<T>(String path, AnonymousPortal callback) async {
  throw UnimplementedError("Not implemented");
}

setBaseHeaders(HttpRequest request) {
  request.response.headers.contentType = ContentType.json;
  request.response.headers.set("Access-Control-Allow-Origin", "*");
  request.response.headers.set("Access-Control-Allow-Methods", "GET, POST");
  request.response.headers.set("Access-Control-Allow-Headers", "Content-Type");
}

typedef AnonymousPortal<T> = FutureOr Function(T data);

typedef NullableString = String?;

class PortalService {
  static PortalService? _instance;
  final PortalCollection _portalCollection = PortalCollection();

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
      setBaseHeaders(request);
      final gatewayMirror = gatewayMirrorUsingFullPath(fullPath);
      try {
        final canPass = await InterceptorService()
            .preHandle(request, gatewayMirror.interceptors);
        if (!canPass) {
          request.response.statusCode = HttpStatus.unprocessableEntity;
          myLogger.w("Interceptor blocked request.", header: "PortalService");
          return request;
        }
      } on IntercetporException catch (e, s) {
        myLogger.e(e);
        myLogger.e(s);
        request.response.statusCode = e.statusCode;
        request.response.reasonPhrase = e.message;
        return request;
      } catch (e, s) {
        myLogger.e(e);
        myLogger.e(s);

        request.response.statusCode = HttpStatus.internalServerError;
        request.response.reasonPhrase = "Couldn't process request.";
        return request;
      }
      try {
        if (gatewayMirror.isGet()) {
          myLogger.d("Processing GET request", header: "PortalService");
          if (request.method != "GET") {
            myLogger.w("Method not allowed", header: "PortalService");
            request.response.statusCode = HttpStatus.methodNotAllowed;
            return request;
          }

          return await handleGet(request, gatewayMirror, fullPath);
        } else if (gatewayMirror.isPost()) {
          if (request.method != "POST") {
            request.response.statusCode = HttpStatus.methodNotAllowed;
            return request;
          }
          myLogger.d("is post");
          return await handlePost(request, gatewayMirror);
        }
      } catch (e, s) {
        myLogger.e("Error processing request: $e");
        myLogger.e(s);

        request.response.statusCode = HttpStatus.internalServerError;
        return request;
      }

      request.response.statusCode = HttpStatus.notFound;
      return request;
    } on PortalException catch (e, s) {
      request.response.statusCode = e.statusCode;
      request.response.write("Error: not found.");
      myLogger.e("Error: $e", stackTrace: s);
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
    myLogger.d("Retrieving portal for path: $fullPath",
        header: "PortalService");
    PortalMirror? portal = _portalByFullPath(fullPath);

    myLogger.d("Portal: $portal", header: "PortalService");
    if (portal == null) {
      throw PortalException(
          message: "No Portal registered with path: $fullPath",
          statusCode: 404);
    }
    var mPath = methodPath(fullPath);
    myLogger.d("Method path: $mPath");
    myLogger.d("portal has gateways: ${portal.gateways.length}");
    for (var element in portal.gateways) {
      myLogger.d(element.getPath);
    }
    final GatewayMirror gateway = portal.gateways.firstWhere(
      (element) => element.getPath == mPath,
      orElse: () => throw Exception("No Gateway registered with path: $mPath"),
    );

    return gateway;
  }

  Future<HttpRequest> handleGet(
      HttpRequest request, GatewayMirror gatewayMirror, String fullPath) async {
    myLogger.d("GET: $gatewayMirror", header: "PortalService --> handleGet");

    MethodParameters methodParameters = await GatewayService()
        .generateGatewayArguments(
            request: request, gatewayMirror: gatewayMirror);
    dynamic response;
    try {
      final dynamic response0 =
          await (gatewayMirror.portalInstanceMirror.invoke(
              Symbol(gatewayMirror.methodMirror.name),
              methodParameters.args,
              methodParameters.namedArgs.map(
                (key, value) => MapEntry(Symbol(key), value),
              )) as FutureOr);
      final jsonResult = ConversionService.encodeJSON(response0);

      myLogger.i(
          "${gatewayMirror.methodMirror.name} --> $response0 --> $jsonResult");
      response = response0;
      request.response.write(jsonResult);
    } on PortalException catch (e, s) {
      myLogger.e("Error: $e",
          stackTrace: s, header: "PortalService --> handleGet");
      request.response.statusCode = e.statusCode;
      response = e.message;
    } catch (e, s) {
      myLogger.e("Error: $e",
          stackTrace: s, header: "PortalService --> handleGet");
      request.response.statusCode = HttpStatus.internalServerError;
    }

    request.response.write(ConversionService.encodeJSON(response));
    await InterceptorService().postHandle(
        request, gatewayMirror.interceptors, methodParameters, response);
    return request;
  }

  Future<HttpRequest> handlePost(
      HttpRequest request, GatewayMirror gatewayMirror) async {
    dynamic result;

    MethodParameters methodParameters = await GatewayService()
        .generateGatewayArguments(
            request: request, gatewayMirror: gatewayMirror);
    try {
      final response0 = await (gatewayMirror.portalInstanceMirror.invoke(
          gatewayMirror.methodMirror.simpleName,
          methodParameters.args,
          methodParameters.namedArgs.map(
            (key, value) => MapEntry(Symbol(key), value),
          )) as FutureOr);
      final jsonResult = ConversionService.encodeJSON(response0);
      myLogger.i(
          "${gatewayMirror.methodMirror.name} --> $response0 --> $jsonResult");

      result = response0;
      myLogger.d("Result: $response0");
      request.response.write(jsonResult);
    } on PortalException catch (e, s) {
      request.response.statusCode = e.statusCode;
      myLogger.e("Error: $e",
          stackTrace: s, header: "PortalService --> handlePost");
      request.response.write(e.message);
    } catch (e, s) {
      myLogger.e("Error: $e", stackTrace: s);

      request.response.statusCode = HttpStatus.internalServerError;
    }

    await InterceptorService().postHandle(
        request, gatewayMirror.interceptors, methodParameters, result);
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
    _portalCollection.add(portal);
  }

  /// Registers a portal with the service.
  ///
  /// This method takes a portal instance, retrieves its path using the [Portal] annotation,
  /// and maps the path to the portal in the [_portalCollection]. This allows for the retrieval of
  /// portal instances based on their path.
  ///
  /// Parameters:
  ///   - [portal]: The portal instance to register.
  registerPortals() {
    myLogger.d("Registering portals...",
        header: "PortalService --> registerPortals");

    final portalCollection = PortalCollector.collect().toSet();
    _portalCollection.clear();
    _portalCollection.addAll(portalCollection);
    myLogger.d("registered portals: $portalCollection",
        header: "PortalService --> registerPortals");
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
  /// instance associated with that path from the [_portalCollection].
  ///
  /// Parameters:
  ///   - [fullPath]: The full path of the request.
  ///
  /// Returns:
  ///   The portal instance associated with the extracted path.
  PortalMirror? _portalByFullPath(String fullPath) {
    dynamic portal;
    try {
      final finalPath = _pathByFullPath(fullPath);
      myLogger.d("Getting portal by path: $finalPath");
      portal = _portalCollection.getByPath(finalPath);
      if (portal == null) {
        throw PortalException(
            message: "No Portal registered with path: $finalPath",
            statusCode: 404);
      }
    } catch (e, s) {
      if (e is PortalException) {
        rethrow;
      }
      myLogger.e("Error: $e", stackTrace: s);
    }
    return portal;
  }
}
