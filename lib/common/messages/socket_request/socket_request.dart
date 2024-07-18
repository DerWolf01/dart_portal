import 'package:wormhole/common/messages/socket_message/socket_message.dart';

import 'package:dart_model/dart_model.dart';

export './socket_request.dart';

/// Represents a request sent over a socket connection.
///
/// This class extends [SocketMessage] to specifically handle request messages. It is
/// generic, allowing for the content of the request to be any model that extends
/// [SerializableModel], ensuring that the content can be easily serialized into JSON.
///
/// Parameters:
///   - [path]: A string representing the path associated with the request. This could
///     be used for routing on the server side.
///   - [content]: The content of the request, which must extend [SerializableModel].
class SocketRequest<T extends SerializableModel> extends SocketMessage<T> {
  SocketRequest(final String path, final T content)
      : super(path, content, SocketMessageType.request);

  bool pending = false;
}
