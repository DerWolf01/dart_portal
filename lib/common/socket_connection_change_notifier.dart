
import 'dart:io';

abstract class SocketConnectionChangeNotifier<WormholeType> {
  List<Function()> preConnectCallbacks = [];
  List<Function(WormholeType)> postConnectCallbacks = [];

  void addPreConnectCallback(Function() callback) {
    preConnectCallbacks.add(callback);
  }

  void removePreConnectCallback(Function(Socket) callback) {
    preConnectCallbacks.remove(callback);
  }

  void addPostConnectCallback(Function(WormholeType) callback) {
    postConnectCallbacks.add(callback);
  }

  void removePostConnectCallback(Function(WormholeType) callback) {
    postConnectCallbacks.remove(callback);
  }

  void callPreConnectCallbacks() {
    for (var callback in preConnectCallbacks) {
      callback();
    }
  }

  void callPostConnectCallbacks(WormholeType session) {
    for (var callback in postConnectCallbacks) {
      callback(session);
    }
  }
}
