import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:portal/portal.dart';
import 'package:portal/services/conversion_service.dart';

class RequestService extends RequestServiceNotifier {
  FutureOr handleRequest(HttpRequest request) async {
    final body = await utf8.decodeStream(request);
    var instance = ConverterService.mapToObject(jsonDecode(body));
    print(instance);
  }

  FutureOr<T?> onSend<T>(dynamic m) async {
    m.pending = true;
    bool pending = true;
    late T? response;

    try {
      oneTimerPortal(
        m.path,
        (data) {
          pending = false;
          response = data;
        },
      );
      await Future.doWhile(
        () {
          return pending;
        },
      );
    } catch (e) {
      print(e);
    }
    return response;
  }
}



class RequestServiceNotifier {
  final List<Function(dynamic value)> _responseListeners = [];

  void addResponseListener(Function(dynamic) listener) {
    _responseListeners.add(listener);
  }

  void removeResponseListener(Function(dynamic) listener) {
    _responseListeners.remove(listener);
  }

  void notifyResponseListeners(dynamic data) {
    for (var listener in _responseListeners) {
      listener(data);
    }
  }
}
