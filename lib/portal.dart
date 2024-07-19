library portal;

export 'package:portal/services/portal_service.dart';
export 'package:portal/middleware/middleware.dart';
export 'package:portal/middleware/middleware_service.dart';

import 'package:portal/reflection.dart';

/// A decorator for classes that act as portals in the application.
///
/// This annotation is used to mark classes that should be recognized as portals
/// within the Portal application. Portals are responsible for handling requests
/// and generating responses. The `path` parameter is used for routing purposes, allowing
/// the application to match incoming requests to the correct portal based on the URL path.

class Portal {
  /// The URL path associated with this portal.
  ///
  /// This path is used by the routing mechanism to direct requests to the appropriate portal.
  final String path;

  String get getPath => path.startsWith("/") ? path : '/$path';

  /// Constructs a [Portal] instance with the given path.
  const Portal(this.path);

  /// Factory method to create a [Portal] instance based on a portal implementation.
  ///
  /// This method uses reflection to find and return the first [Portal] annotation
  /// associated with the provided portal class. It is useful for dynamically
  /// obtaining portal metadata at runtime.
  factory Portal.fromInstance(dynamic portal) {
    return instanceMetadata(portal).whereType<Portal>().first;
  }
}

/// An abstract class representing a type of request that can be handled by the application.
///
/// This class serves as a base for more specific request handler annotations, such as
/// [RequestHandler] and [ResponseHandler]. It includes a `path` property that is used
/// for routing requests to the appropriate handler based on the URL path.

abstract class RequestType {
  /// The URL path associated with this request type.
  ///
  /// This path is used by the routing mechanism to match incoming requests to their handlers.
  final String path;

  String get getPath => path.startsWith("/") ? path : '/$path';

  /// Constructs a [RequestType] instance with the given path.
  const RequestType(this.path);
}

/// A decorator for methods that handle specific types of requests.
///
/// This annotation is used to mark methods within portal classes that should be invoked
/// to handle specific requests. The `path` parameter is used for routing, allowing the application
/// to match incoming requests to the correct method based on the URL path.

class RequestHandler extends RequestType {
  /// Constructs a [RequestHandler] instance with the given path.
  const RequestHandler(super.path);
}

/// A decorator for methods that handle responses to specific types of requests.
///
/// This annotation is used to mark methods within portal classes that should be invoked
/// to handle responses. The `path` parameter is used for routing, allowing the application
/// to match outgoing responses to the correct method based on the URL path.

class ResponseHandler extends RequestType {
  /// Constructs a [ResponseHandler] instance with the given path.
  const ResponseHandler(super.path);
}
