import 'dart:async';
import 'dart:io';

import 'middleware.dart';

/// A service for managing middleware in the application.
///
/// This class provides functionality to register, remove, and execute
/// middleware for incoming requests. Middleware can be used to perform
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
  final List<Middleware> middlewares = [];

  /// Registers a middleware to be used by the service.
  ///
  /// Adds the given [middleware] to the list of middlewares that will be
  /// applied to requests.
  ///
  /// Parameters:
  ///   - [middleware]: The middleware to register.
  void registerMiddleware(Middleware middleware) {
    middlewares.add(middleware);
  }

  /// Removes a middleware from the service.
  ///
  /// Removes the given [middleware] from the list of middlewares, so it
  /// will no longer be applied to requests.
  ///
  /// Parameters:
  ///   - [middleware]: The middleware to remove.
  void removeMiddleware(Middleware middleware) {
    middlewares.remove(middleware);
  }

  /// Executes the pre-handle phase of middlewares for a given path.
  ///
  /// Iterates through all registered middlewares and executes their
  /// pre-handle method if they are associated with the given [path] and
  /// if they have a pre-handle method defined. Stops executing further
  /// middlewares if any middleware returns `false`.
  ///
  /// Parameters:
  ///   - [path]: The path of the request.
  ///   - [data]: The data that has arrived.
  ///
  /// Returns:
  ///   A [FutureOr<bool>] indicating whether to continue processing the request.
  FutureOr<bool> preHandle(String path, HttpRequest request) async {
    print("middleware preHandle");
    for (var middleware in middlewares.where(
      (element) => element.preHandle != null && element.path == path,
    )) {
      if (!(await middleware.preHandle!(request))) {
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
      {required dynamic portalAccepted,
      dynamic? portalReturned}) async {
    for (var middleware in middlewares.where(
      (element) => element.postHandle != null && element.path == path,
    )) {
      await middleware.postHandle!(portalAccepted,
          portalReturned: portalReturned);
    }
  }
}
