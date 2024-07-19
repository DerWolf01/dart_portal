import 'dart:mirrors';

class CollectorService {
  List<AnotatedClass<T>> searchClassesUsingAnnotation<T>() {
    final classes = <AnotatedClass<T>>[];

    MirrorSystem mirrorSystem = currentMirrorSystem();
    mirrorSystem.libraries.forEach((lk, l) {
      l.declarations.forEach((dk, d) {
        if (d is ClassMirror) {
          ClassMirror cm = d;

          for (var md in cm.metadata) {
            InstanceMirror metadata = md;
            if (metadata.reflectee is T) {
              classes.add(AnotatedClass<T>(
                  classMirror: cm, anotatedWith: metadata.reflectee as T));
            }
          }
        }
      });
    });

    return classes;
  }
}

class AnotatedClass<AnotatedWith> {
  AnotatedClass({required this.classMirror, required this.anotatedWith});

  ClassMirror classMirror;
  AnotatedWith anotatedWith;
}
