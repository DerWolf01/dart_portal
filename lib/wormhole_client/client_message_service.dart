import 'dart:async';

import 'package:wormhole/common/messages/socket_message_service.dart';
import 'package:wormhole/common/messages/socket_request/socket_request.dart';
import 'package:dart_model/dart_model.dart';

import 'package:wormhole/wormhole.dart';
import 'package:wormhole/wormhole_client/wormhole_client.dart';
import 'package:wormhole/common/component/component.dart';
import 'package:wormhole/common/controller/controller.dart';
import 'package:wormhole/common/messages/socket_response/socket_response.dart';
import 'package:wormhole/common/middleware/middleware_service.dart';

class ClientMessageService extends SocketMessageService
    with SocketMessageTypeRecognizer {
  WormholeClient get wormholeClient => WormholeClient();

  @override
  handleRequest(Map<String, dynamic> message) async {
    var path = message["path"];
    print('handleRequest-path: $path');
    var pingedMethod =
        controllerService.methodMirrorByFullPath<RequestHandler>(path);
    if (pingedMethod is AnnotatedMethod<RequestHandler>) {
      SerializableModel? argument;
      try {
        argument = pingedMethod.invokeMethodArgumentInstance(
            constructorName: "fromMap", positionalArguments: [message]);
        if (argument == null) {
          throw Exception("Couldn't parse Model.");
        }
      } catch (e) {
        throw Exception("""Couldn't parse Model.
$e""");
      }
      var res = await pingedMethod.invoke([argument]);
      if (res is SerializableModel) {
        await send(SocketResponse(message["path"], res));
        MiddlewareService().postHandle(path,
            controllerAccepted: argument, controllerReturned: res);
      }
    }
  }

  @override
  handleResponse(Map<String, dynamic> message) async {
    var path = message["path"];
    print('handleResponse-path: $path');
    AnnotatedMethod? pingedMethod =
        controllerService.methodMirrorByFullPath<ResponseHandler>(path);
    if (pingedMethod is AnnotatedMethod<ResponseHandler>) {
      var argument = pingedMethod.invokeMethodArgumentInstance(
          constructorName: "fromMap", positionalArguments: [message]);

      await pingedMethod.invoke([argument]);
      await MiddlewareService().postHandle(path,
          controllerAccepted: argument, controllerReturned: null);
    } else {
      throw Exception(
          "${pingedMethod?.partOf.runtimeType}.${(pingedMethod as AnnotatedMethod).method.simpleName}(${pingedMethod.methodArgumentType()}) is not a ResponseHandler!");
    }
    notifyResponseListeners(message);
  }

  @override
  FutureOr<SerializableModel?> send(SocketMessage m) async {
    wormholeClient.send(m.toJson());
    return await super.onSend(m);
  }
}
