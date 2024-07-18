import 'dart:async';

import 'package:characters/characters.dart';
import 'package:wormhole/common/component/component.dart';
import 'package:wormhole/common/controller/controller.dart';
import 'package:dart_model/dart_model.dart';

export './controller_service.dart';

class ControllerService {
  final Map<String, dynamic> _controllerMap = {};
  final Map<String, List<AnonymousController>> _anonymousControllerMap = {};
  static ControllerService? _instance;

  ControllerService._internal();

  /// Factory constructor for creating or retrieving a singleton instance of [ControllerService].
  factory ControllerService() {
    _instance ??= ControllerService._internal();
    return _instance!;
  }

  /// Registers a controller with the service.
  ///
  /// This method takes a controller instance, retrieves its path using the [Controller] annotation,
  /// and maps the path to the controller in the [_controllerMap]. This allows for the retrieval of
  /// controller instances based on their path.
  ///
  /// Parameters:
  ///   - [controller]: The controller instance to register.
  registerController(dynamic controllerImpl) {
    Controller controller = Controller.byImplementation(controllerImpl);
    var path = controller.getPath;

    _controllerMap[path] = controller;
  }

  /// Retrieves a controller instance based on its path.
  ///
  /// This method looks up the controller in the [_controllerMap] using the provided path and returns
  /// the instance if found.
  ///
  /// Parameters:
  ///   - [path]: The path of the controller to retrieve.
  ///
  /// Returns:
  ///   The controller instance associated with the given path, if found.
  dynamic getController(String path) {
    return _controllerMap[path];
  }

  /// Retrieves a controller instance based on the full path of a request.
  ///
  /// This method parses the full path to extract the controller path, then retrieves the controller
  /// instance associated with that path from the [_controllerMap].
  ///
  /// Parameters:
  ///   - [fullPath]: The full path of the request.
  ///
  /// Returns:
  ///   The controller instance associated with the extracted path.
  dynamic controllerByFullPath(String fullPath) {
    print(_controllerMap);
    dynamic controller;
    try {
      controller = _controllerMap[_pathByFullPath(fullPath)];
      if (controller == null) {
        throw Exception("No Controller registered with path: $fullPath");
      }
    } catch (e) {
      print("Error: $e");
    }
    return controller;
  }

  /// Extracts the controller path from the full path of a request.
  ///
  /// This method processes the full path to isolate and return the path segment that corresponds
  /// to the controller. It is used internally to map requests to their respective controllers.
  ///
  /// Parameters:
  ///   - [rawFullPath]: The full path of the request.
  ///
  /// Returns:
  ///   The extracted path segment corresponding to the controller.
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
  /// This method separates the controller path from the full path and returns the remaining
  /// part, which corresponds to the method path within the controller.
  ///
  /// Parameters:
  ///   - [fullPath]: The full path of the request.
  ///
  /// Returns:
  ///   The method path extracted from the full path.
  String methodPath(String fullPath) {
    var controllerPath = _pathByFullPath(fullPath);
    var methodPath = fullPath.substring(controllerPath.length);

    return methodPath;
  }

  /// Invokes a method on a controller using a map as the argument.
  ///
  /// This method dynamically invokes a controller method identified by an [AnnotatedMethod]
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

  /// Finds an annotated method within a controller based on the full request path.
  ///
  /// This method locates a method within a controller that matches a specific request path.
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
      var controller = controllerByFullPath(fullPath);
      if (controller == null) {
        throw Exception("No Controller registered with path: $fullPath");
      }
      var mPath = methodPath(fullPath);

      AnnotatedMethod? res = annotatedMethods<AnnotatedWith>(controller)
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

typedef AnonymousController = FutureOr Function(SerializableModel data);

FutureOr oneTimerController(String path, AnonymousController callback) async {
  ControllerService()._anonymousControllerMap[path] ??= [];
  ControllerService()
      ._anonymousControllerMap[path]!
      .add((SerializableModel data) async {
    await callback(data);
    ControllerService()._anonymousControllerMap[path]!.remove(callback);
  });
}
