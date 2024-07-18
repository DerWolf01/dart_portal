import 'dart:isolate';
import 'package:wormhole/common/messages/simple_message/simple_message.dart';
import 'package:wormhole/wormhole.dart';
import 'client/controller/controller_example.dart';
import 'main.reflectable.dart';
import 'server/controller/controller_example.dart';

void main() async {
  initializeReflectable();
  ControllerService().registerController(ControllerExample());
  await WormholeServer.init();

  Isolate.spawn((message) async {
    initializeReflectable();
    ControllerService().registerController(ClientControllerExample());

    await WormholeClient.connect();
    var res = await ClientMessageService()
        .send(SocketRequest("/example/test", SimpleMessage("Hello Server")));
  }, "");
}
