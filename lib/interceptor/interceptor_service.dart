import 'dart:async';
import 'dart:io';
import 'dart:mirrors';
import 'intercept.dart';

class DispensableInterceptor<T> extends Interceptor<T> {
  DispensableInterceptor({this.preHandleCallback, this.postHandleCallback});
  final InterceptorCallback? preHandleCallback;

  final InterceptorCallback? postHandleCallback;

  @override
  FutureOr<void> postHandle(
      {required HttpRequest request,
      required T portalReceived,
      portalGaveBack}) async {
    if (postHandleCallback == null) {
      return;
    }
    postHandleCallback!(request);
  }

  @override
  FutureOr<bool> preHandle(HttpRequest request) async {
    if (preHandleCallback == null) {
      return true;
    }

    return preHandleCallback!(request);
  }
}

typedef InterceptorCallback = FutureOr<bool> Function(HttpRequest request);

/// A service for managing interceptor in the application.
///
/// This class provides functionality to register, remove, and execute
/// interceptor for incoming requests. Interceptor can be used to perform
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

  List<DispensableInterceptor> absoluteInterceptors = [];

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
  FutureOr<bool> preHandle(
      HttpRequest request, List<Interceptor> interceptors) async {
    for (final interceptor in absoluteInterceptors) {
      if (!(await interceptor.preHandle(request))) {
        return false;
      }
    }
    for (final interceptor in interceptors) {
      if (interceptor.preHandle == null) return true;
      if (!(await interceptor.preHandle(request))) {
        return false;
      }
    }
    return true;
  }

  FutureOr<void> postHandle(HttpRequest request, List<Interceptor> interceptors,
      dynamic portalReceived, dynamic portalGaveBack) async {
    for (final interceptor in absoluteInterceptors) {
      await interceptor.postHandle(
          request: request, portalReceived: portalReceived);
    }
    for (final interceptor in interceptors) {
      if (interceptor.postHandle == null) continue;
      await interceptor.postHandle!(
          request: request,
          portalReceived: portalReceived,
          portalGaveBack: portalGaveBack);
    }
  }
}

extension MiddlewareFilter on List<InstanceMirror> {
  preHandle(String path) => where(
        (element) {
          final reflectee = element.reflectee as Interceptor;
          return (reflectee).preHandle != null;
        },
      );

  postHandle(String path) =>
      where((element) => (element.reflectee as Interceptor).postHandle != null);
}

intercept({InterceptorCallback? preHandle, InterceptorCallback? posthandle}) {
  MiddlewareService().absoluteInterceptors.add(DispensableInterceptor(
      preHandleCallback: preHandle, postHandleCallback: posthandle));
}
