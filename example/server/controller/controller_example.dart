import 'package:wormhole/common/messages/simple_message/simple_message.dart';
import 'package:wormhole/wormhole.dart';

@component
@Controller("/example")
class ControllerExample {
  @RequestHandler("/test")
  handle(SerializableModel data) {
    print(data);
    return SimpleMessage("Hello, World!");
  }
}
