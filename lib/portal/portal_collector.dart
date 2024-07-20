import 'dart:mirrors';

import 'package:portal/interceptor/intercept.dart';
import 'package:portal/portal/gateway.dart';
import 'package:portal/portal/portal_impl.dart';
import 'package:portal/reflection.dart';
import 'package:portal/services/collection_service.dart';

class PortalCollector {
  static List<PortalMirror> collect() {
    print('Collecting portals');
    final portals =
        CollectorService().searchClassesUsingAnnotation<Portal>().map((e) {
      return PortalMirror(
          classMirror: e.classMirror,
          portal: e.anotatedWith,
          gateways: gateways(e.classMirror));
    }).toList();
    if (portals.isEmpty) {
      print('No portals found');
    }else{
      print('Portals found');
      print(portals.length);
      print(portals);
    }
    return portals;
  }

  static List<GatewayMirror> gateways(ClassMirror classMirror) {
    print("Collecting data from portal ${classMirror.simpleName}");
    final List<GatewayMirror> gateways = [];
    for (final method in methods(classMirror)) {
      if (MirrorSystem.getName(method.simpleName) == "handle") {
        print('Collecting data from gateway-method handle');
      }
      final Gateway? gateway = method.metadata
          .where(
            (element) => element.type.isSubclassOf(reflectClass(Gateway)),
          )
          .firstOrNull
          ?.reflectee as Gateway?;
      if (gateway == null) {
        continue;
      }

      gateways.add(GatewayMirror(
        portalClassMirror: classMirror,
        methodMirror: method,
        gateway: gateway,
        interceptors: methodAnotations<Interceptor>(method),
      ));
    }
    return gateways;
  }
}
