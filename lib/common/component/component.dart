import 'dart:async';

import 'package:reflectable/reflectable.dart';
import 'package:dart_model/dart_model.dart';
export './component.dart';

class Reflector extends Reflectable {
  const Reflector()
      : super(
          typeCapability,
          libraryCapability,
          metadataCapability,
          declarationsCapability,
          typeAnnotationQuantifyCapability,
          instanceInvokeCapability,
          newInstanceCapability,
        );
}

const Reflector component = Reflector();

ClassMirror classMirror(dynamic element) {
  if (element.runtimeType == Type) {
    return component.reflectType(element) as ClassMirror;
  }
  return component.reflect(element).type;
}

InstanceMirror instanceMirror(dynamic element) {
  return component.reflect(element);
}

List<Object> metadata(dynamic element) {
  return instanceMirror(element).type.metadata;
}

List<MethodMirror> methods(dynamic element) {
  return classMirror(element)
      .declarations
      .values
      .whereType<MethodMirror>()
      .toList();
}

List<AnnotatedMethod<T>> annotatedMethods<T>(dynamic element) {
  return methods(element)
      .where((element) => element.metadata.whereType<T>().firstOrNull != null)
      .map(
        (e) => AnnotatedMethod<T>(element, e, e.metadata.whereType<T>().first),
      )
      .toList();
}

@component
class AnnotatedMethod<AnotatedWith> {
  final dynamic partOf;
  final MethodMirror method;
  final AnotatedWith annotation;

  AnnotatedMethod(this.partOf, this.method, this.annotation);

  Type methodArgumentType() {
    return method.parameters.first.type.reflectedType;
  }

  dynamic invokeMethodArgumentInstance(
      {required constructorName, required List<dynamic> positionalArguments}) {
    var res = classMirror(methodArgumentType())
        .newInstance("$constructorName", positionalArguments);
    return res;
  }

  FutureOr<T>? invoke<T extends Model>(
      List<dynamic> positionalArguments) async {
    return await (instanceMirror(partOf)
        .invoke(method.simpleName, positionalArguments) as FutureOr<T>);
  }

  Future<T> invokeUsingMap<T extends Model?>(Map map) async {
    dynamic argument;
    try {
      argument = invokeMethodArgumentInstance(
          constructorName: "fromMap", positionalArguments: [map]);
    } catch (e) {
      print(e);
    }
    return await (instanceMirror(partOf).invoke(method.simpleName, [argument])
        as FutureOr<T>);
  }
}
