import 'dart:async';
import 'dart:mirrors';

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
    var res = reflectClass(methodArgumentType())
        .newInstance(Symbol("$constructorName"), positionalArguments);
    return res;
  }

  FutureOr<T>? invoke<T>(List<dynamic> positionalArguments) async {
    return await (reflect(partOf)
            .invoke(method.simpleName, positionalArguments))
        .reflectee as FutureOr<T>;
  }

  Future<T> invokeUsingMap<T>(Map map) async {
    dynamic argument;
    try {
      argument = invokeMethodArgumentInstance(
          constructorName: "fromMap", positionalArguments: [map]);
    } catch (e) {
      print(e);
    }
    return await (reflect(partOf).invoke(method.simpleName, [argument])
        as FutureOr<T>);
  }
}

List<MethodMirror> methods(dynamic element) {
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
