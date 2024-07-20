import 'dart:mirrors';

import 'package:portal/interceptor/intercept.dart';
import 'package:portal/portal/gateway.dart';
import 'package:portal/portal/portal_impl.dart';
import 'package:portal/reflection.dart';
import 'package:portal/services/collection_service.dart';

class PortalCollector {
  static List<PortalMirror> collect() {
    print('Collecting data from portal');
    return CollectorService().searchClassesUsingAnnotation<Portal>().map((e) {
      return PortalMirror(
          classMirror: e.classMirror,
          portal: e.anotatedWith,
          gateways: gateways(e.classMirror));
    }).toList();
  }

  static List<GatewayMirror> gateways(ClassMirror classMirror) {
    final List<GatewayMirror> gateways = [];
    for (final method in methods(classMirror)) {
      final Gateway? gateway = method.metadata
          .where(
            (element) => element.type.isAssignableTo(reflectClass(Gateway)),
          )
          .firstOrNull
          ?.reflectee as Gateway?;
      if (gateway == null) {
        continue;
      }

      gateways.add(GatewayMirror(
        classMirror: classMirror,
        gateway: gateway,
        interceptors: methodAnotations<Intercept>(method),
      ));
    }
    return gateways;
  }
}
