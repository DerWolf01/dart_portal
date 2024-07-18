import 'dart:async';
import 'package:wormhole/common/middleware/middleware.dart';
import 'package:wormhole/common/middleware/middleware_service.dart';

/// Registers an anonymous middleware with the [MiddlewareService].
///
/// This function allows for the dynamic registration of middleware
/// based on the provided [path]. Optional [preHandle] and [postHandle]
/// callbacks can be specified for additional processing before and after
/// the main middleware logic.
///
/// Parameters:
///   - [path]: The path on which the middleware should be applied.
///   - [preHandle]: An optional callback to be executed before the main middleware logic.
///   - [postHandle]: An optional callback to be executed after the main middleware logic.
///
/// Returns:
///   A [FutureOr] representing the asynchronous operation of registering the middleware.
FutureOr anonymousMiddleware(String path,
    {PreHandle? preHandle, PostHandle? postHandle}) {
  Middleware(path, postHandle: postHandle, preHandle: preHandle).register();
}
