import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:portal/example/sign_up_form.dart';
import 'package:portal/portal.dart';

/// Callback type for handling pre-interceptor actions.
///
/// Takes a [Uint8List] as an argument and returns a [FutureOr<bool>].
typedef PreHandle = FutureOr<bool> Function(HttpRequest data);

/// Callback type for handling post-interceptor actions.
///
/// Takes a generic type [T] extending [Model] as an argument and returns a [FutureOr<void>].
typedef PostHandle<T> = FutureOr<void> Function(T portalAccepted,
    {dynamic? portalReturned});

/// A class representing a interceptor component.
///
/// This class allows for the creation and registration of interceptor
/// components within the application. Intercept components can perform
/// actions before and after the main processing of a request.
///
/// Parameters:
///   - [path]: The path on which the interceptor should be applied.
///   - [preHandle]: An optional callback to be executed before the main interceptor logic.
///   - [postHandle]: An optional callback to be executed after the main interceptor logic.
///
///
///

class Intercept<T> {
  /// Constructs a [Intercept] instance.
  ///
  /// The constructor requires a [path] and optionally accepts [preHandle]
  /// and [postHandle] callbacks for additional processing.
  const Intercept({this.preHandle, this.postHandle});

  /// An optional pre-handle callback.
  final PreHandle? preHandle;

  /// An optional post-handle callback.
  final PostHandle<T>? postHandle;

  /// Registers the interceptor with the [MiddlewareService].
  ///
  /// This method adds the current interceptor instance to the interceptor
  /// service for activation and use within the application.
  register() {
    // register interceptor
    MiddlewareService().registerMiddleware(this);
  }
}
