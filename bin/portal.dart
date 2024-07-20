import 'dart:io';

import 'package:portal/example/server/controller/auth_portal.dart';
import 'package:portal/example/sign_up_form.dart';
import 'package:portal/portal.dart';
import 'package:portal/portal/gateway.dart';
import 'package:portal/portal/portal_impl.dart';
import 'package:portal/portal_server.dart';

void main<T>() async {
  PortalService().registerPortals();
  await PortalServer.init();
}



// @Portal("/auth")
// class AuthPortal {
//   @AuthInterceptor()
//   @Post("/sign-in")
//   handle(SignUpForm data) {
//     print(data);
//     return SignUpResult("jdsonfdksjfnsekjfsj");
//   }
// }
