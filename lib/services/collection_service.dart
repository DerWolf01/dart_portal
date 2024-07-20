import 'dart:mirrors';

import 'package:portal/portal.dart';
import 'package:portal/portal/portal_impl.dart';

class CollectorService {
  List<AnotatedClass<T>> searchClassesUsingAnnotation<T>() {
    final classes = <AnotatedClass<T>>[];

    MirrorSystem mirrorSystem = currentMirrorSystem();

    for (final library in mirrorSystem.libraries.entries) {
      print(library.key);
      for (final libraryDecleration in library.value.declarations.entries) {
        final isClassMirror = libraryDecleration.value is ClassMirror;

        if (isClassMirror) {
          ClassMirror classMirror = libraryDecleration.value as ClassMirror;
          for (final anotationInstanceMirror in classMirror.metadata) {
            final isPortal = anotationInstanceMirror.type
                .isAssignableTo(reflectType(Portal));
            print(anotationInstanceMirror.type.toString() == "Portal");
            if (isPortal) {
              print("Found Portal --> $classMirror");
              classes.add(AnotatedClass(
                  classMirror: classMirror,
                  anotatedWith: anotationInstanceMirror.reflectee as T));
            }
          }
        }
      }
    }
    return classes;
  }

  List<ClassMirror> searchClassesByType<T>() {
    final classes = <ClassMirror>[];

    MirrorSystem mirrorSystem = currentMirrorSystem();

    for (final library in mirrorSystem.libraries.entries) {
      print(library.key);
      for (final libraryDecleration in library.value.declarations.entries) {
        final isClassMirror = libraryDecleration.value is ClassMirror;

        if (isClassMirror) {
          ClassMirror classMirror = libraryDecleration.value as ClassMirror;
          if (classMirror.isAssignableTo(reflectClass(T))) {
            classes.add(classMirror);
          }
        }
      }
    }
    return classes;
  }
}

class AnotatedClass<AnotatedWith> {
  AnotatedClass({required this.classMirror, required this.anotatedWith});

  ClassMirror classMirror;
  AnotatedWith anotatedWith;
}


