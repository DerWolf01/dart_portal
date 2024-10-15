import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_conversion/dart_conversion.dart';
import 'package:portal/my_logger.dart';

class RequestService extends RequestServiceNotifier {
  FutureOr handleRequest(HttpRequest request) async {
    final body = await utf8.decodeStream(request);
    var instance = ConversionService.mapToObject(jsonDecode(body));
    myLogger.d(instance);
  }
}

class RequestServiceNotifier {
  final List<Function(dynamic value)> _responseListeners = [];

  void addResponseListener(Function(dynamic) listener) {
    _responseListeners.add(listener);
  }

  void notifyResponseListeners(dynamic data) {
    for (var listener in _responseListeners) {
      listener(data);
    }
  }

  void removeResponseListener(Function(dynamic) listener) {
    _responseListeners.remove(listener);
  }
}
