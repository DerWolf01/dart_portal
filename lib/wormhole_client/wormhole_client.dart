import 'dart:convert';
import 'dart:io';
import 'package:wormhole/common/socket_connection_change_notifier.dart';
import 'package:wormhole/wormhole_client/client_message_service.dart';
import 'package:wormhole/common/messages/socket_message/socket_message.dart'
    as messages;

export 'wormhole_client.dart';

/// A client for managing connections and communications with a Wormhole server.
///
/// This class handles connecting to the server, sending and receiving messages,
/// and managing the socket connection's lifecycle. It extends the
/// [SocketConnectionChangeNotifier] to provide notifications on connection changes.
class WormholeClient extends SocketConnectionChangeNotifier<WormholeClient> {
  /// The socket connection to the server.
  Socket? _socket;

  /// Singleton instance of [WormholeClient].
  static WormholeClient? _instance;

  /// Private constructor for singleton pattern.
  WormholeClient._internal();

  /// Connects to the Wormhole server and starts listening for messages.
  ///
  /// Attempts to connect to the server at the specified [host] and [port].
  /// Upon successful connection, it starts listening for incoming messages.
  ///
  /// Returns the singleton instance of [WormholeClient].
  static Future<WormholeClient?> connect() async {
    var client = WormholeClient._internal();
    await client._connect('localhost', 3000);
    client.listen();
    _instance ??= client;
    return client;
  }

  /// Factory constructor to access the singleton instance.
  ///
  /// Throws an exception if the client has not been initialized.
  factory WormholeClient() {
    if (_instance == null) throw Exception('WormholeClient not initialized');
    return _instance!;
  }

  /// Initiates a connection to the server.
  ///
  /// Connects to the server using the provided [host] and [port].
  /// Notifies pre and post connection callbacks.
  Future<void> _connect(String host, int port) async {
    try {
      callPreConnectCallbacks();
      _socket = await Socket.connect(host, port);
      if (_socket == null) {
        throw Exception('Failed to connect. ');
      }
      callPostConnectCallbacks(this);
    } catch (e) {
      print('Failed to connect: $e');
    }
  }

  /// Starts listening for messages from the server.
  ///
  /// Sets up listeners for data, errors, and disconnection events on the socket.
  void listen() {
    _socket?.listen((event) {
      receive(event);
    }, onError: (e) {
      print('Error: $e');
    }, onDone: () {
      print('Disconnected');
    });
  }

  /// Sends a message to the server.
  ///
  /// This method takes a message in the form of a string, checks if there is an active
  /// socket connection, and if so, sends the message over the socket. It logs the message
  /// that was sent. If the socket is not connected, it logs a warning. This method also
  /// handles any errors that occur during the sending process and logs them.
  ///
  /// Parameters:
  ///   - [message]: The message to be sent to the server.
  Future<void> send(String message) async {
    if (_socket == null) {
      print('Not connected to any server');
      return;
    }

    try {
      _socket?.write(message);
      print('Sent: $message');
      return await _socket?.done;
    } catch (e) {
      print('Failed to send message: $e');
    }
  }

  /// Handles receiving messages from the server.
  ///
  /// Decodes the incoming [data] and forwards it to the [ClientMessageService] for processing.
  Future<void> receive(dynamic data) async {
    final decodedData = utf8.decode(data);
    print(decodedData);
    final Map<String, dynamic> json = jsonDecode(decodedData);

    return await ClientMessageService().receive(json);
  }

  /// Disconnects from the server.
  ///
  /// This method checks if the socket connection is not null, indicating an active connection.
  /// If there is an active connection, it attempts to close the socket and logs a message indicating
  /// the disconnection from the server. If the socket cannot be closed, it catches the exception and
  /// logs an error message. If there is no active connection, it logs a message indicating that there
  /// is no server connection to disconnect from.
  Future<void> disconnect() async {
    if (_socket == null) {
      print('Not connected to any server');
      return;
    }

    try {
      await _socket!.close();
      print('Disconnected from server');
    } catch (e) {
      print('Failed to disconnect: $e');
    }
  }
}

/// Provides a global access point to the [WormholeClient] instance.
///
/// This getter ensures that any part of the application can access the singleton instance
/// of [WormholeClient] to perform operations like sending messages.
WormholeClient get wormholeClient => WormholeClient();

/// Sends a message to the server using the [WormholeClient] instance.
///
/// This function takes a [SocketMessage] object as an argument, which it sends to the server
/// through the [WormholeClient] instance. It ensures that the message is sent asynchronously
/// and waits for the send operation to complete.
send(messages.SocketMessage message) async {
  await wormholeClient.send(message.toJson());
}
