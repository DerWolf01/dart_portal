import 'package:wormhole/common/messages/socket_message/socket_message.dart';
import 'package:dart_model/dart_model.dart';

/// Represents a response sent over a socket connection.
///
/// This class extends [SocketMessage] to specifically handle response messages. It is
/// generic, allowing for the content of the response to be any model that extends
/// [SerializableModel], ensuring that the content can be easily serialized into JSON.
/// This facilitates the transmission of structured data as a response to a request.
///
/// Parameters:
///   - [path]: A string representing the path associated with the response. This could
///     be used for routing on the client side to ensure the response is handled by the
///     correct receiver.
///   - [content]: The content of the response, which must extend [SerializableModel].
///     This allows the response data to be serialized into JSON format for transmission.
class SocketResponse<T extends SerializableModel> extends SocketMessage<T> {
  SocketResponse(final String path, final T content)
      : super(path, content, SocketMessageType.response);
}
