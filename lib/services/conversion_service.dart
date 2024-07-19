import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

class ConverterService {
  static Map<String, dynamic> objectToMap(dynamic object) {
    var mirror = reflect(object);
    var classMirror = mirror.type;

    var map = <String, dynamic>{};

    classMirror.declarations.forEach((symbol, declaration) {
      if (declaration is VariableMirror && !declaration.isStatic) {
        var fieldName = MirrorSystem.getName(symbol);
        var fieldValue = mirror.getField(symbol).reflectee;

        map[fieldName] = fieldValue;
      }
    });

    return map;
  }

  static T mapToObject<T>(Map<String, dynamic> map, {Type? type}) {
    var classMirror = reflectClass(type ?? T);
    var instance = classMirror.newInstance(const Symbol(''), map.values.toList());
    //
    // map.forEach((key, value) {
    //   var fieldName = MirrorSystem.getSymbol(key);
    //   var fieldValue = value;
    //   instance.setField(fieldName, fieldValue);
    // });

    return instance.reflectee;
  }

  static Future<Map<String, dynamic>> requestToMap(HttpRequest request) async {
    final body = await utf8.decodeStream(request);
    return jsonDecode(body);
  }

  static Future<T> requestToObject<T>(HttpRequest request, {Type? type}) async {
    return mapToObject<T>(await streamToMap(request), type: type);
  }

  static streamToMap(Stream<List<int>> stream) async {
    final body = await utf8.decodeStream(stream);
    print(body.split("&").map(
          (e) => MapEntry<String, dynamic>(e.split("=")[0], e.split("=")[1]),
        ));
    return Map<String, dynamic>.fromEntries(body.split("&").map(
          (e) => MapEntry<String, dynamic>(e.split("=")[0], e.split("=")[1]),
        ));
  }
}
