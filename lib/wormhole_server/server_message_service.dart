import 'dart:async';
import 'package:wormhole/common/component/component.dart';
import 'package:wormhole/common/controller/controller.dart';
import 'package:wormhole/common/messages/socket_message_service.dart';
import 'package:wormhole/common/messages/socket_response/socket_response.dart';
import 'package:wormhole/common/middleware/middleware_service.dart';
import 'package:dart_model/dart_model.dart';

import 'package:wormhole/wormhole.dart';
import 'package:wormhole/wormhole_server/session/client_session.dart';

/// Provides server-side message handling services for the Wormhole application.
///
/// This service is responsible for processing incoming socket messages, both requests and responses,
/// and dispatching them to the appropriate handlers. It extends [SocketMessageService] and implements
/// the [SocketMessageTypeRecognizer] to facilitate this functionality.
class ServerMessageService extends SocketMessageService
    with SocketMessageTypeRecognizer {
  /// The user session associated with this service instance.
  ///
  /// This [ClientSession] object represents the session of the client connected to the server,
  /// allowing the server to send messages back to the client.
  final ClientSession userSession;

  ServerMessageService(this.userSession);

  /// Handles incoming request messages from clients.
  ///
  /// This method overrides the [handleRequest] method from [SocketMessageService] to provide
  /// specific logic for handling request messages. It decodes the message, identifies the appropriate
  /// controller method to handle the request, and invokes that method. If the method returns a result
  /// that is a [SerializableModel], it serializes the model to JSON and sends it back to the client.
  ///
  /// Parameters:
  ///   - [message]: The request message as a map.
  @override
  handleRequest(Map<String, dynamic> message) async {
    var path = message["path"];
    print('handleRequest-path: $path');
    var pingedMethod =
        controllerService.methodMirrorByFullPath<RequestHandler>(path);
    print("pingedMethod: $pingedMethod");
    if (pingedMethod is AnnotatedMethod<RequestHandler>) {
      try {
        var argument = pingedMethod.invokeMethodArgumentInstance(
            constructorName: "fromMap", positionalArguments: [message]);
        var res = await pingedMethod.invoke([argument]);

        if (res is SerializableModel) {
          await send(SocketResponse(message["path"], res));
          await MiddlewareService().postHandle(path,
              controllerAccepted: argument, controllerReturned: res);
        }
      } catch (e) {
        print(e);
      }
    }
  }

  /// Handles incoming response messages from clients.
  ///
  /// This method overrides the [handleResponse] method from [SocketMessageService] to provide
  /// specific logic for handling response messages. It identifies the appropriate controller
  /// method to handle the response and invokes it. It also notifies any listeners about the
  /// response.
  ///
  /// Parameters:
  ///   - [message]: The response message as a map.
  @override
  FutureOr<SerializableModel?> handleResponse(
      Map<String, dynamic> message) async {
    var path = message["path"];
    print('handleResponse-path: $path');
    var pingedMethod =
        controllerService.methodMirrorByFullPath<RequestHandler>(path);
    if (pingedMethod is AnnotatedMethod<RequestHandler>) {
      try {
        var argument = pingedMethod.invokeMethodArgumentInstance(
            constructorName: "fromMap", positionalArguments: [message]);
        await pingedMethod.invoke([argument]);
        await MiddlewareService().postHandle(path,
            controllerAccepted: argument, controllerReturned: null);
      } catch (e) {
        print(e);
      }
      notifyResponseListeners(message);
    }

    return null;
  }

  /// Sends a serialized model to the client.
  ///
  /// This method overrides the [send] method from [SocketMessageService] to provide
  /// specific logic for sending messages to the client. It serializes the [SerializableModel]
  /// to JSON and sends it through the user session.
  ///
  /// Parameters:
  ///   - [m]: The model to be sent, which must be a [SerializableModel].
  @override
  FutureOr<SerializableModel?> send(SocketMessage m) async {
    userSession.send(m.toJson());
    return await super.onSend(m);
  }
}
