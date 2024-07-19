import 'dart:async';
import 'dart:mirrors';
import 'package:characters/characters.dart';
import 'package:portal/portal.dart';
import 'package:portal/reflection.dart';
import 'package:portal/services/collection_service.dart';

PortalService get portalService => PortalService();

class PortalService {
  final Map<String, dynamic> _portalMap = {};
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
    for (final portalMirror
        in CollectorService().searchClassesUsingAnnotation<Portal>()) {
      final portal =
          portalMirror.classMirror.newInstance(Symbol(""), []).reflectee;
      var path = portalMirror.anotatedWith.getPath;
      print("registering  $portal with $path");
      _portalMap[path] = portal;
    }
  }

  registerPortal(dynamic portal) {
    final mirror = reflectClass(portal);
    final path = metadata(type: portal.runtimeType).first.getPath;
    _portalMap[path] = portal;
  }

  /// Retrieves a portal instance based on its path.
  ///
  /// This method looks up the portal in the [_portalMap] using the provided path and returns
  /// the instance if found.
  ///
  /// Parameters:
  ///   - [path]: The path of the portal to retrieve.
  ///
  /// Returns:
  ///   The portal instance associated with the given path, if found.
  dynamic getPortal(String path) {
    return _portalMap[path];
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
  dynamic portalByFullPath(String fullPath) {
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
  dynamic callMethodFromMap(AnnotatedMethod m, Map map) {
    var argument = m.invokeMethodArgumentInstance(
        constructorName: "fromMap", positionalArguments: [map]);
    return m.partOf.invoke(m.method.simpleName, [argument]);
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
  AnnotatedMethod? methodMirrorByFullPath<AnnotatedWith extends RequestType>(
      String fullPath) {
    try {
      var portal = portalByFullPath(fullPath);
      if (portal == null) {
        throw Exception("No Portal registered with path: $fullPath");
      }
      var mPath = methodPath(fullPath);

      AnnotatedMethod? res = annotatedMethods<AnnotatedWith>(portal)
          .where(
            (e) => e.annotation.getPath == mPath,
          )
          .firstOrNull;

      print("Annotated method found --> ${res?.method.simpleName} --> $res  ");

      return res;
    } catch (e) {
      print("Error: $e");
    }
    return null;
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
