import 'dart:async';
import 'dart:io';
import 'package:characters/characters.dart';
import 'package:dart_conversion/dart_conversion.dart';
import 'package:portal/interceptor/interceptor_exception.dart';
import 'package:portal/interceptor/interceptor_service.dart';
import 'package:portal/portal/gateway.dart';
import 'package:portal/portal/portal_collector.dart';
import 'package:portal/portal/portal_exception.dart';
import 'package:portal/portal/portal_impl.dart';
import 'package:portal/reflection.dart';
import 'package:portal/services/collection_service.dart';

PortalService get portalService => PortalService();

class PortalService {
  final Map<String, PortalMirror> _portalMap = {};
  final Map<String, List<AnonymousPortal<dynamic>>> _anonymousPortalMap = {};
  static PortalService? _instance;

  PortalService._internal();

  /// Factory constructor for creating or retrieving a singleton instance of [PortalService].
  factory PortalService() {
    _instance ??= PortalService._internal();
    return _instance!;
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

  registerPortal(dynamic portal) {
    final path = metadata(type: portal.runtimeType).first.getPath;
    _portalMap[path] = portal;
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
  PortalMirror _portalByFullPath(String fullPath) {
    print(_portalMap);
    dynamic portal;
    try {
      portal = _portalMap[_pathByFullPath(fullPath)];
      if (portal == null) {
        throw Exception("No Portal registered with path: $fullPath");
      }
    } catch (e) {
      print("Error: $e");
    }
    return portal;
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

  dynamic callMethod(AnnotatedMethod m, Map<String, dynamic> map) async {
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
    var portal = _portalByFullPath(fullPath);
    print(portal);
    if (portal == null) {
      throw Exception("No Portal registered with path: $fullPath");
    }
    var mPath = methodPath(fullPath);
    print("Method path: $mPath");
    print("portal has gateways: ${portal.gateways.length}");
    portal.gateways.forEach((element) {
      print(element.getPath);
    });
    final GatewayMirror gateway = portal.gateways.firstWhere(
      (element) => element.getPath == mPath,
      orElse: () => throw Exception("No Gateway registered with path: $mPath"),
    );

    return gateway;
  }

  Future<HttpRequest> callGateway(
    String fullPath,
    HttpRequest request,
  ) async {
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
  }

  Future<HttpRequest> handleGet(
      HttpRequest request, GatewayMirror gatewayMirror, String fullPath) async {
    final argumentObject = ConversionService.mapToObject(
        request.uri.queryParameters,
        type: gatewayMirror.methodArgumentType());

    dynamic response;
    try {
      response = await gatewayMirror.invoke([argumentObject]);
    } on PortalException catch (e) {
      request.response.statusCode = e.statusCode;
      response = e.message;
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
    }
    print(response);
    request.response.write(ConversionService.convertToStringOrJson(response));
    await MiddlewareService().postHandle(
        request, gatewayMirror.interceptors, argumentObject, response);
    return request;
  }

  Future<HttpRequest> handlePost(
      HttpRequest request, GatewayMirror gatewayMirror) async {
    var object = await ConversionService.requestToObject(request,
        type: gatewayMirror.methodArgumentType());

    dynamic result;
    try {
      result = await gatewayMirror.invoke([object]);
    } on PortalException catch (e) {
      request.response.statusCode = e.statusCode;
      result = e.message;
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
    }
    print(result);
    request.response.write(ConversionService.convertToStringOrJson(result));
    await MiddlewareService()
        .postHandle(request, gatewayMirror.interceptors, object, result);
    return request;
  }
}

typedef AnonymousPortal<T> = FutureOr Function(T data);

FutureOr oneTimerPortal<T>(String path, AnonymousPortal callback) async {
  PortalService()._anonymousPortalMap[path] ??= [];
  PortalService()._anonymousPortalMap[path]!.add(((T data) async {
        await callback(data);
        PortalService()._anonymousPortalMap[path]!.remove(callback);
      }) as AnonymousPortal<dynamic>);
}
