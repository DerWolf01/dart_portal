import 'dart:mirrors';

import 'package:portal/portal/gateway.dart';
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

  String get getPath {
    String path = this.path;

    if (path.startsWith("/")) {
      path = '/$path';
    }
    if (path.endsWith("/")) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

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

class PortalMirror {
  PortalMirror(
      {required this.classMirror,
      required this.portal,
      required this.gateways});

  ClassMirror classMirror;
  Portal portal;
  List<GatewayMirror> gateways;
}
