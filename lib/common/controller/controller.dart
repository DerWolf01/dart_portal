import 'package:wormhole/common/component/component.dart';
export './controller.dart';

/// A decorator for classes that act as controllers in the application.
///
/// This annotation is used to mark classes that should be recognized as controllers
/// within the Wormhole application. Controllers are responsible for handling requests
/// and generating responses. The `path` parameter is used for routing purposes, allowing
/// the application to match incoming requests to the correct controller based on the URL path.
@component
class Controller {
  /// The URL path associated with this controller.
  ///
  /// This path is used by the routing mechanism to direct requests to the appropriate controller.
  final String path;

  String get getPath => path.startsWith("/") ? path : '/$path';

  /// Constructs a [Controller] instance with the given path.
  const Controller(this.path);

  /// Factory method to create a [Controller] instance based on a controller implementation.
  ///
  /// This method uses reflection to find and return the first [Controller] annotation
  /// associated with the provided controller class. It is useful for dynamically
  /// obtaining controller metadata at runtime.
  factory Controller.byImplementation(dynamic controller) {
    return metadata(controller).whereType<Controller>().first;
  }
}

/// An abstract class representing a type of request that can be handled by the application.
///
/// This class serves as a base for more specific request handler annotations, such as
/// [RequestHandler] and [ResponseHandler]. It includes a `path` property that is used
/// for routing requests to the appropriate handler based on the URL path.
@component
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
/// This annotation is used to mark methods within controller classes that should be invoked
/// to handle specific requests. The `path` parameter is used for routing, allowing the application
/// to match incoming requests to the correct method based on the URL path.
@component
class RequestHandler extends RequestType {
  /// Constructs a [RequestHandler] instance with the given path.
  const RequestHandler(super.path);
}

/// A decorator for methods that handle responses to specific types of requests.
///
/// This annotation is used to mark methods within controller classes that should be invoked
/// to handle responses. The `path` parameter is used for routing, allowing the application
/// to match outgoing responses to the correct method based on the URL path.
@component
class ResponseHandler extends RequestType {
  /// Constructs a [ResponseHandler] instance with the given path.
  const ResponseHandler(super.path);
}
