import 'dart:io';
import 'package:wormhole/wormhole_server/session/client_session.dart';
import 'package:wormhole/wormhole_server/session/client_sessions.dart';

/// Represents the server in the Wormhole application.
///
/// This class encapsulates the functionality required to initialize, configure,
/// and run a server that listens for incoming socket connections. It manages
/// client sessions and handles incoming connections by creating and tracking
/// [ClientSession] instances.
class WormholeServer {
  /// The host address the server listens on.
  final String host;

  /// The port number the server listens on.
  final int port;

  /// The underlying server socket.
  final ServerSocket _socket;

  /// Singleton instance of [WormholeServer].
  static WormholeServer? _instance;

  /// Private constructor for [WormholeServer].
  ///
  /// Initializes a new instance of the server with the provided socket, host, and port.
  WormholeServer._internal(
      {required ServerSocket socket, required this.host, required this.port})
      : _socket = socket;

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
  ///   A [Future] that resolves to the singleton instance of [WormholeServer] if
  ///   the server is successfully started, or null if the server fails to start.
  static Future<WormholeServer?> init(
      {String host = 'localhost', int port = 3000}) async {
    try {
      final server = await ServerSocket.bind(host, port);
      _instance ??=
          WormholeServer._internal(socket: server, host: host, port: port);

      if (_instance != null) {
        print("server --> listening on localhost:3000");
      } else {
        throw Exception("failed to start server");
      }
    } catch (e) {
      print('Failed to start server: $e');
    }

    return _instance;
  }

  /// Factory constructor for [WormholeServer].
  ///
  /// Returns the singleton instance of [WormholeServer]. Throws an exception if
  /// the server has not been initialized.
  factory WormholeServer() {
    if (_instance == null) throw Exception('WormholeServer not initialized');
    return _instance!;
  }

  /// Starts listening for incoming connections.
  ///
  /// This method sets up the server to listen on the configured host and port.
  /// For each incoming connection, it creates a new [ClientSession], starts it,
  /// and adds it to the list of active sessions.
  listen() {
    print("listening on $host:$port");
    _socket.listen(
          (socket) {

        var session = ClientSession(socket);
        session.start();
        ClientSessions().addSession(session);

      },
      onError: (error) {
        print('Socket error: $error');
      },
      onDone: () {
        print('Socket closed');
      },
    );
  }
}

/// Provides a global accessor for the [WormholeServer] singleton.
WormholeServer get wormholeServer => WormholeServer();