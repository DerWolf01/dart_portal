import 'package:wormhole/wormhole.dart';

@component
@Controller("/example")
class ClientControllerExample {
  @ResponseHandler("/test")
  handle(SerializableModel data) {
    print(data);
  }
}
