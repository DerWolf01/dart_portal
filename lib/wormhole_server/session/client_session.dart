import 'dart:convert';
import 'dart:io';
import 'package:wormhole/common/messages/socket_message_service.dart';
import 'package:wormhole/wormhole.dart';

/// Represents a client session with a unique session ID and socket connection.
///
/// This class encapsulates the functionality for managing a client's session,
/// including starting the session, receiving data, sending messages, and closing
/// the session. It uses a [Socket] for communication and assigns a unique session ID
/// based on the current timestamp.
class ClientSession {
  /// The socket connection to the client.
  final Socket _socket;

  /// The unique session ID for this client session.
  final String sessionId;

  /// Constructs a [ClientSession] with a given socket.
  ///
  /// Initializes the session ID based on the current timestamp and sets up
  /// the server message service for handling incoming and outgoing messages.
  ClientSession(
    this._socket,
  ) : sessionId = DateTime.now().millisecondsSinceEpoch.toString() {
    socketMessageService = ServerMessageService(this);
  }

  /// The service for handling messages sent to and received from the client.
  late final SocketMessageService socketMessageService;

  /// Starts listening for data on the socket and handles incoming messages.
  ///
  /// This method sets up listeners for data, errors, and the closing of the socket.
  /// It decodes incoming data and forwards it to the server message service for processing.
  void start() {
    print('User session started with session ID: $sessionId');

    _socket.listen(
      (data) async {
        final decodedData = utf8.decode(data);
        print('Received data: $decodedData');
        final json = jsonDecode(decodedData);
        try {
          final String path = json['path'];
          if (!(await MiddlewareService().preHandle(path, data))) {
            return;
          }
        } catch (e) {
          print(e);
        }
        await socketMessageService.receive(json);
      },
      onError: (error) {
        // Handle socket error
        throw Exception('Socket error: $error');
      },
      onDone: () {
        // Handle socket closed
        ClientSessions().removeSession(this);
        print('Socket closed');
      },
    );
  }

  /// Sends a message to the client through the socket.
  ///
  /// Encodes the given message as a string and writes it to the socket.
  /// Waits for the send operation to complete before returning.
  ///
  /// Parameters:
  ///   - [message]: The message to send to the client.
  Future<void> send(String message) async {
    _socket.write(message);
    return await _socket.done;
  }

  /// Closes the socket connection to the client.
  ///
  /// Waits for the close operation to complete before returning.
  Future<void> close() async {
    return await _socket.close();
  }
}
