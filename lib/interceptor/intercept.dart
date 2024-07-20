import 'dart:async';
import 'dart:io';

abstract class Interceptor<T> {
  /// Constructs a [Interceptor] instance.
  ///
  /// The constructor requires a [path] and optionally accepts [preHandle]
  /// and [postHandle] callbacks for additional processing.
  const Interceptor();

  /// An optional pre-handle callback.
  FutureOr<int> preHandle(HttpRequest request);

  /// An optional post-handle callback.
  FutureOr<void> postHandle(
      {required HttpRequest request,
      required T portalReceived,
      dynamic? portalGaveBack});
}
