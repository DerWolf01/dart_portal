import 'dart:async';
import 'dart:mirrors';

import 'package:dart_conversion/dart_conversion.dart';
import 'package:portal/interceptor/intercept.dart';
import 'package:portal/portal/portal_impl.dart';

abstract class Gateway {
  /// The URL path associated with this request type.
  ///
  /// This path is used by the routing mechanism to match incoming requests to their handlers.
  final String path;

  String get getPath => path.startsWith("/") ? path : '/$path';

  /// Constructs a [RequestType] instance with the given path.
  const Gateway(this.path);
}

/// A decorator for methods that handle specific types of requests.
///
/// This annotation is used to mark methods within portal classes that should be invoked
/// to handle specific requests. The `path` parameter is used for routing, allowing the application
/// to match incoming requests to the correct method based on the URL path.

class Get extends Gateway {
  /// Constructs a [Get] instance with the given path.
  const Get(super.path);
}

/// A decorator for methods that handle responses to specific types of requests.
///
/// This annotation is used to mark methods within portal classes that should be invoked
/// to handle responses. The `path` parameter is used for routing, allowing the application
/// to match outgoing responses to the correct method based on the URL path.

class Post extends Gateway {
  /// Constructs a [Post] instance with the given path.
  const Post(super.path);
}

class GatewayMirror {
  GatewayMirror(
      {required this.portalClassMirror,
      required this.methodMirror,
      required this.gateway,
      required this.interceptors})
      : portalInstanceMirror = portalClassMirror.newInstance(Symbol(''), []);

  String get getPath => gateway.getPath;

  final ClassMirror portalClassMirror;
  final InstanceMirror portalInstanceMirror;
  final MethodMirror methodMirror;
  final Gateway gateway;
  final List<Interceptor> interceptors;

  bool isGet() => gateway is Get;

  bool isPost() => gateway is Post;

  TypeMirror? methodArgumentType() {
    return methodMirror.parameters
        .where(
          (element) => element.metadata.isEmpty,
        )
        .firstOrNull
        ?.type;
  }
}
