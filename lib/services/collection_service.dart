import 'dart:mirrors';

import 'package:portal/portal.dart';
import 'package:portal/portal/portal_impl.dart';
import 'package:portal/portal_server.dart';
import 'package:portal/portal_server.dart';
import 'package:portal/portal_server.dart';

class CollectorService {
  List<AnotatedClass<T>> searchClassesUsingAnnotation<T>() {
    final classes = <AnotatedClass<T>>[];

    final portalMirror = reflectClass(Portal);
    for (final library in currentMirrorSystem().libraries.entries) {
      for (final libraryDecleration in library.value.declarations.entries) {
        final isClassMirror = libraryDecleration.value is ClassMirror;

        if (isClassMirror) {
          ClassMirror classMirror = libraryDecleration.value as ClassMirror;
          for (final anotationInstanceMirror in classMirror.metadata) {
            final isPortal =
                anotationInstanceMirror.type.isSubclassOf(portalMirror) ||
                    anotationInstanceMirror.type.isSubtypeOf(portalMirror) ||
                    anotationInstanceMirror.type.isAssignableTo(portalMirror) ||
                    anotationInstanceMirror.reflectee.runtimeType == Portal;

            if (isPortal) {
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

    for (final library in currentMirrorSystem().libraries.entries) {
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
