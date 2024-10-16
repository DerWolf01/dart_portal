// ignore_for_file: unused_import

import 'dart:io';

import 'package:dart_conversion/dart_conversion.dart';
import 'package:portal/example/server/controller/auth_portal_example.dart';
import 'package:portal/my_logger.dart';
import 'package:portal/portal.dart';

/// Provides a global accessor for the [PortalServer] singleton.
PortalServer get portalServer => PortalServer();

/// Represents the server in the Portal application.
///
/// This class encapsulates the functionality required to initialize, configure,
/// and run a server that listens for incoming socket connections. It manages
/// client sessions and handles incoming connections by creating and tracking
/// [ClientSession] instances.
class PortalServer {
  /// The underlying server socket.

  /// Singleton instance of [PortalServer].
  static PortalServer? _instance;

  final HttpServer server;

  /// Factory constructor for [PortalServer].
  ///
  /// Returns the singleton instance of [PortalServer]. Throws an exception if
  /// the server has not been initialized.
  factory PortalServer() {
    if (_instance == null) throw Exception('PortalServer not initialized');
    return _instance!;
  }

  /// Private constructor for [PortalServer].
  ///
  /// Initializes a new instance of the server with the provided socket, host, and port.
  PortalServer._internal({
    required this.server,
  });

  /// Starts listening for incoming connections.
  ///
  /// This method sets up the server to listen on the configured host and port.
  /// For each incoming connection, it creates a new [ClientSession], starts it,
  /// and adds it to the list of active sessions.
  void listen() {
    server.listen((HttpRequest request) async {
      myLogger.i('''
  Ip-Adress: ${request.connectionInfo?.remoteAddress}
  Method: ${request.method}
  Headers: { ${request.headers} }
  Uri: ${request.uri.path}
  Query: ${request.uri.queryParametersAll}
          ''', header: "PortalServer --> Request");

      await portalService.callGateway(request.uri.path, request);

      await request.response.flush();
      await request.response.close();
    });
    myLogger.d("listening on ${server.address.address}:${server.port}");
  }

  /// Initializes the server asynchronously.
  ///
  /// Attempts to bind the server to the specified host and port. If successful,
  /// it creates or returns the singleton instance of the server. If the server
  /// fails to start, it myLogger.ds an error message.
  ///
  /// Parameters:
  ///   - [host]: The host address to bind the server to. Defaults to 'localhost'.
  ///   - [port]: The port number to bind the server to. Defaults to 3000.
  ///
  /// Returns:
  ///   A [Future] that resolves to the singleton instance of [PortalServer] if
  ///   the server is successfully started, or null if the server fails to start.
  static Future<PortalServer?> init(
      {String host = 'localhost',
      int port = 3000,
      SecurityContext? securityContext,
      bool enableLogging = false,
      bool enableConversionLogging = false}) async {
    try {
      if (enableConversionLogging) {
        ConversionService.enableLogging();
      } else {
        ConversionService.disableLogging();
      }
      MyLogger.init(enabled: enableLogging);
      PortalService().registerPortals();
      final server = securityContext == null
          ? await HttpServer.bind(host, port)
          : await HttpServer.bindSecure(host, port, securityContext);
      _instance ??= PortalServer._internal(server: server);

      if (_instance == null) {
        throw Exception("failed to start server");
      }
    } catch (e, s) {
      myLogger.e('Failed to start http-server: $e',
          header: "PortalServer", stackTrace: s);
    }
    _instance?.listen();
    return _instance;
  }
}
