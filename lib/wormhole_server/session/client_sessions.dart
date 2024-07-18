import 'package:wormhole/common/messages/socket_message/socket_message.dart';
import 'package:wormhole/wormhole_server/session/client_session.dart';

/// Manages the collection of active client sessions.
///
/// This class provides functionality to add, remove, and retrieve client sessions.
/// It implements a singleton pattern to ensure that there is only one instance
/// of the session collection throughout the application.
class ClientSessions {
  static ClientSessions? _instance;

  ClientSessions._internal();

  /// Factory constructor to get the singleton instance of [ClientSessions].
  factory ClientSessions() {
    _instance ??= ClientSessions._internal();
    return _instance!;
  }

  final List<ClientSession> _clientSessions = [];

  /// Adds a [ClientSession] to the collection.
  ///
  /// Parameters:
  ///   - [session]: The client session to add.
  void addSession(ClientSession session) {
    _clientSessions.add(session);
    print("added client session ${session.sessionId}");
  }

  /// Removes a [ClientSession] from the collection based on its session ID.
  ///
  /// Parameters:
  ///   - [session]: The client session to remove.
  void removeSession(ClientSession session) {
    _clientSessions
        .removeWhere((element) => element.sessionId == session.sessionId);
  }

  /// Retrieves all active client sessions.
  ///
  /// Returns:
  ///   A list of all active [ClientSession]s.
  List<ClientSession> getClientSessions() {
    return _clientSessions;
  }

  /// Finds a [ClientSession] by its session ID.
  ///
  /// Parameters:
  ///   - [sessionId]: The ID of the session to find.
  ///
  /// Returns:
  ///   The [ClientSession] with the matching session ID.
  ClientSession sessionById(String sessionId) {
    return _clientSessions
        .firstWhere((session) => session.sessionId == sessionId);
  }
}

/// Retrieves a client session by its ID.
///
/// Parameters:
///   - [id]: The ID of the session to retrieve.
///
/// Returns:
///   The [ClientSession] with the specified ID.
ClientSession getSession(String id) {
  return ClientSessions().sessionById(id);
}

/// Sends a message to a client session identified by its session ID.
///
/// Parameters:
///   - [sessionId]: The ID of the session to send the message to.
///   - [message]: The message to send.
///
/// Returns:
///   A future that completes when the message has been sent.
sendBySessionId(String sessionId, SocketMessage message) async {
  await getSession(sessionId).send(message.toJson());
}
