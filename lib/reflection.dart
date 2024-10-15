import 'dart:async';
import 'dart:mirrors';

import 'package:portal/my_logger.dart';

List<AnnotatedMethod<T>> annotatedMethods<T>(dynamic element) {
  List<MethodMirror> methodsList = methods(element);

  return methodsList
      .where((element) =>
          element.metadata
              .map((e) => e.type.reflectedType)
              .whereType<T>()
              .firstOrNull !=
          null)
      .map(
        (e) => AnnotatedMethod<T>(element, e,
            e.metadata.map((e) => e.reflectee).whereType<T>().first),
      )
      .toList();
}

instanceMetadata(dynamic object) {
  return reflect(object).type.metadata.map(
        (e) => e.reflectee,
      );
}

metadata<T>({Type? type}) {
  return reflectClass(type ?? T).metadata.map(
        (e) => e.reflectee,
      );
}

List<T> methodAnotations<T>(MethodMirror method) {
  return method.metadata
      .where((e) => e.type.isSubclassOf(reflectClass(T)))
      .map((e) => e.reflectee as T)
      .toList();
}

List<MethodMirror> methods(dynamic element) {
  if (element is ClassMirror) {
    return element.declarations.values.whereType<MethodMirror>().toList();
  }
  if (element is Type) {
    return reflectClass(element)
        .declarations
        .values
        .whereType<MethodMirror>()
        .toList();
  }

  return reflect(element)
      .type
      .declarations
      .values
      .whereType<MethodMirror>()
      .toList();
}

class AnnotatedMethod<AnotatedWith> {
  final dynamic partOf;
  final MethodMirror method;
  final AnotatedWith annotation;

  AnnotatedMethod(this.partOf, this.method, this.annotation);

  FutureOr<T>? invoke<T>(List<dynamic> positionalArguments) async {
    return await (reflect(partOf)
            .invoke(method.simpleName, positionalArguments))
        .reflectee as FutureOr<T>;
  }

  dynamic invokeMethodArgumentInstance(
      {required constructorName, required List<dynamic> positionalArguments}) {
    var res = reflectClass(methodArgumentType())
        .newInstance(Symbol("$constructorName"), positionalArguments);
    return res;
  }

  Future<T> invokeUsingMap<T>(Map map) async {
    dynamic argument;
    try {
      argument = invokeMethodArgumentInstance(
          constructorName: "fromMap", positionalArguments: [map]);
    } catch (e, s) {
      myLogger.e(e);
      myLogger.e(s);
    }
    return await (reflect(partOf).invoke(method.simpleName, [argument])
        as FutureOr<T>);
  }

  Type methodArgumentType() {
    return method.parameters.first.type.reflectedType;
  }
}
