import 'dart:async';
import 'dart:typed_data';
import 'package:dart_model/dart_model.dart';
import 'package:wormhole/wormhole.dart';

/// Callback type for handling pre-middleware actions.
///
/// Takes a [Uint8List] as an argument and returns a [FutureOr<bool>].
typedef PreHandle = FutureOr<bool> Function(Uint8List data);

/// Callback type for handling post-middleware actions.
///
/// Takes a generic type [T] extending [Model] as an argument and returns a [FutureOr<void>].
typedef PostHandle<T extends SerializableModel> = FutureOr<void>
    Function(T controllerAccepted, {T? controllerReturned});

/// A class representing a middleware component.
///
/// This class allows for the creation and registration of middleware
/// components within the application. Middleware components can perform
/// actions before and after the main processing of a request.
///
/// Parameters:
///   - [path]: The path on which the middleware should be applied.
///   - [preHandle]: An optional callback to be executed before the main middleware logic.
///   - [postHandle]: An optional callback to be executed after the main middleware logic.
///
///
///
@component
class Middleware<T extends SerializableModel> {
  /// Constructs a [Middleware] instance.
  ///
  /// The constructor requires a [path] and optionally accepts [preHandle]
  /// and [postHandle] callbacks for additional processing.
  Middleware(this.path, {this.preHandle, this.postHandle});

  /// The path on which the middleware is applied.
  final String path;

  /// An optional pre-handle callback.
  PreHandle? preHandle;

  /// An optional post-handle callback.
  PostHandle<T>? postHandle;

  /// Registers the middleware with the [MiddlewareService].
  ///
  /// This method adds the current middleware instance to the middleware
  /// service for activation and use within the application.
  register() {
    // register middleware
    MiddlewareService().registerMiddleware(this);
  }
}

var m = Middleware<SocketMessage>("/example",
    preHandle: (accepts) async => true,
    postHandle: (controllerAccepted, {controllerReturned}) async =>
        print(controllerAccepted))
  ..register();
