import 'dart:io';

import 'package:portal/portal.dart';

/// Represents the server in the Portal application.
///
/// This class encapsulates the functionality required to initialize, configure,
/// and run a server that listens for incoming socket connections. It manages
/// client sessions and handles incoming connections by creating and tracking
/// [ClientSession] instances.
class PortalServer {
  final HttpServer server;

  /// The underlying server socket.

  /// Singleton instance of [PortalServer].
  static PortalServer? _instance;

  /// Private constructor for [PortalServer].
  ///
  /// Initializes a new instance of the server with the provided socket, host, and port.
  PortalServer._internal({
    required this.server,
  });

  /// Initializes the server asynchronously.
  ///
  /// Attempts to bind the server to the specified host and port. If successful,
  /// it creates or returns the singleton instance of the server. If the server
  /// fails to start, it prints an error message.
  ///
  /// Parameters:
  ///   - [host]: The host address to bind the server to. Defaults to 'localhost'.
  ///   - [port]: The port number to bind the server to. Defaults to 3000.
  ///
  /// Returns:
  ///   A [Future] that resolves to the singleton instance of [PortalServer] if
  ///   the server is successfully started, or null if the server fails to start.
  static Future<PortalServer?> init(
      {String host = 'localhost', int port = 3000}) async {
    PortalService().registerPortals();
    MiddlewareService().registerMiddlewares();
    try {
      final server = await HttpServer.bind(host, port);
      _instance ??= PortalServer._internal(server: server);

      if (_instance != null) {
        print("http-server --> listening on localhost:3000");
      } else {
        throw Exception("failed to start server");
      }
    } catch (e) {
      print('Failed to start http-server: $e');
    }
    _instance?.listen();
    return _instance;
  }

  /// Factory constructor for [PortalServer].
  ///
  /// Returns the singleton instance of [PortalServer]. Throws an exception if
  /// the server has not been initialized.
  factory PortalServer() {
    if (_instance == null) throw Exception('PortalServer not initialized');
    return _instance!;
  }

  /// Starts listening for incoming connections.
  ///
  /// This method sets up the server to listen on the configured host and port.
  /// For each incoming connection, it creates a new [ClientSession], starts it,
  /// and adds it to the list of active sessions.
  listen() {
    server.listen((HttpRequest request) async {
      print(
          'Request from ${request.connectionInfo?.remoteAddress}:${request.connectionInfo?.remotePort}');

      print('Request: ${request.uri.path}');
      await portalService.callGateway(request.uri.path, request);
      await request.response.close();
    });
    print("listening on ${server.address.address}:${server.port}");
  }
}

/// Provides a global accessor for the [PortalServer] singleton.
PortalServer get portalServer => PortalServer();
