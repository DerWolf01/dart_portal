import 'dart:async';
import 'dart:io';

import 'package:dart_conversion/dart_conversion.dart';
import 'package:portal/interceptor/interceptor_exception.dart';
import 'package:portal/my_logger.dart';

import 'intercept.dart';

/// A service for managing interceptor in the application.
///
/// This class provides functionality to register, remove, and execute
/// interceptor for incoming requests. Interceptor can be used to perform
/// actions before and after the main processing of a request, such as
/// authentication checks or logging.
class InterceptorService {
  /// The singleton instance of [InterceptorService].
  static InterceptorService? _instance;

  /// Factory constructor to provide a singleton instance.
  ///
  /// If an instance already exists, it returns that; otherwise, it creates
  /// a new instance using the private constructor.
  factory InterceptorService() {
    _instance ??= InterceptorService._internal();
    return _instance!;
  }

  /// Private constructor for the singleton pattern.
  InterceptorService._internal();

  FutureOr<void> postHandle(HttpRequest request, List<Interceptor> interceptors,
      MethodParameters portalReceived, dynamic portalGaveBack) async {
    for (final interceptor in interceptors) {
      try {
        await interceptor.postHandle(
            request: request,
            portalReceived: portalReceived,
            portalGaveBack: portalGaveBack);
      } catch (e, s) {
        if (e is IntercetporException) {
          rethrow;
        }
        myLogger.e("Error in postHandle for ${interceptor.runtimeType} $e",
            stackTrace: s);
      }
    }
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
  FutureOr<bool> preHandle(
      HttpRequest request, List<Interceptor> interceptors) async {
    for (final interceptor in interceptors) {
      myLogger.d("Calling preHandle for ${interceptor.runtimeType}",
          header: "InterceptorService");
      if (!(await interceptor.preHandle(request))) {
        myLogger.w("${interceptor.runtimeType} blocked request",
            header: "InterceptorService");
        return false;
      }
      myLogger.i("${interceptor.runtimeType} passed",
          header: "InterceptorService");
    }
    return true;
  }
}
