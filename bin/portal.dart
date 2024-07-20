import 'dart:mirrors';

import 'package:portal/portal.dart';
import 'package:portal/portal_server.dart';

void main<T>() async {
  PortalService().registerPortals();
  await PortalServer.init(mirrorSystem: currentMirrorSystem());
}

// @Portal("/auth")
// class AuthPortalExample {
//   @AuthInterceptor()
//   @Post("/sign-in")
//   handle(SignUpForm data) {
//     print(data);
//     return SignUpResult("jdsonfdksjfnsekjfsj");
//   }
// }
