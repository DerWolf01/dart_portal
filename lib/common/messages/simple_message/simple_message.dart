import 'package:wormhole/common/component/component.dart';

import 'package:dart_model/dart_model.dart';

@component
class SimpleMessage extends SerializableModel {
  const SimpleMessage(this.message);
  final String message;

  @override
  Map<String, dynamic> toMap() {
    return {
      "message": message,
    };
  }

  SimpleMessage.fromMap(Map<String, dynamic> map) : message = map["message"];
}
