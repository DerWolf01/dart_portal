import 'dart:async';
import 'dart:io';
import 'dart:mirrors';

import 'package:portal/services/collection_service.dart';

import 'intercept.dart';

/// A service for managing interceptor in the application.
///
/// This class provides functionality to register, remove, and execute
/// interceptor for incoming requests. Intercept can be used to perform
/// actions before and after the main processing of a request, such as
/// authentication checks or logging.
class MiddlewareService {
  /// Private constructor for the singleton pattern.
  MiddlewareService._internal();

  /// The singleton instance of [MiddlewareService].
  static MiddlewareService? _instance;

  /// Factory constructor to provide a singleton instance.
  ///
  /// If an instance already exists, it returns that; otherwise, it creates
  /// a new instance using the private constructor.
  factory MiddlewareService() {
    _instance ??= MiddlewareService._internal();
    return _instance!;
  }

  /// A list to hold all registered middlewares.
  final List<InstanceMirror> middlewares = [];

  void registerMiddlewares() {
    for (final mirror in CollectorService().searchClassesByType<Intercept>()) {
      middlewares.add(mirror.newInstance(const Symbol(""), []));
    }
  }

  /// Registers a interceptor to be used by the service.
  ///
  /// Adds the given [middleware] to the list of middlewares that will be
  /// applied to requests.
  ///
  /// Parameters:
  ///   - [interceptor]: The interceptor to register.
  void registerMiddleware(Intercept middleware) {
    middlewares.add(reflect(middleware));
  }

  /// Removes a interceptor from the service.
  ///
  /// Removes the given [middleware] from the list of middlewares, so it
  /// will no longer be applied to requests.
  ///
  /// Parameters:
  ///   - [interceptor]: The interceptor to remove.
  void removeMiddleware(Intercept middleware) {
    middlewares.remove(middleware);
  }

  /// Executes the pre-handle phase of middlewares for a given path.
  ///
  /// Iterates through all registered middlewares and executes their
  /// pre-handle method if they are associated with the given [path] and
  /// if they have a pre-handle method defined. Stops executing further
  /// middlewares if any interceptor returns `false`.
  ///
  /// Parameters:
  ///   - [path]: The path of the request.
  ///   - [data]: The data that has arrived.
  ///
  /// Returns:
  ///   A [FutureOr<bool>] indicating whether to continue processing the request.
  FutureOr<bool> preHandle(String path, HttpRequest request) async {
    print("interceptor preHandle");

    print(path);
    for (var middleware in middlewares.preHandle(path)) {
      if (!(await middleware.invoke("preHandle", [path]))) {
        return false;
      }
    }
    return true;
  }

  /// Executes the post-handle phase of middlewares for a given path.
  ///
  /// Iterates through all registered middlewares and executes their
  /// post-handle method if they are associated with the given [path] and
  /// if they have a post-handle method defined.
  ///
  /// Parameters:
  ///   - [path]: The path of the request.
  ///   - [data]: The data model associated with the request.
  ///
  /// Returns:
  ///   A [FutureOr<void>] representing the asynchronous operation.
  FutureOr<void> postHandle(String path,
      {required dynamic portalAccepted, dynamic portalReturned}) async {
    for (var middleware in middlewares.postHandle(path)) {
      await middleware.postHandle!(portalAccepted,
          portalReturned: portalReturned);
    }
  }
}

extension MiddlewareFilter on List<InstanceMirror> {
  preHandle(String path) =>
      where(
            (element) {
          final reflectee = element.reflectee as Intercept;
          return (reflectee).preHandle != null;
        },
      );

  postHandle(String path) =>
      where(
              (element) => (element.reflectee as Intercept).postHandle != null
      );
}
