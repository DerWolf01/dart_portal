import 'package:wormhole/common/component/component.dart';
import 'package:dart_model/dart_model.dart';
export './socket_message.dart';

/// Enum representing the types of socket messages.
enum SocketMessageType { request, response }

/// An abstract class representing a generic socket message.
///
/// This class serves as a base for specific types of socket messages, encapsulating
/// common properties and behaviors such as serialization to JSON.
@component
abstract class SocketMessage<T extends SerializableModel>
    extends SerializableModel {
  /// Constructs a [SocketMessage] instance with the given path, content, and type.
  ///
  /// Parameters:
  ///   - [path]: A string representing the path associated with the message.
  ///   - [content]: The content of the message, constrained to types extending [Model].
  ///   - [type]: The type of the socket message, defined by [SocketMessageType].
  SocketMessage(this.path, this.content, this.type);

  bool pending = false;

  /// The type of the socket message.
  final SocketMessageType type;

  /// The path associated with the socket message.
  final String path;

  /// The content of the socket message.
  final T content;

  /// Serializes the socket message to a map.
  ///
  /// Overrides the [toMap] method from [Model] to include the path, type, and content of the message.
  @override
  Map<String, dynamic> toMap() {
    return {"path": path, "type": type.index, ...content.toMap()};
  }
}
