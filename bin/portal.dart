import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:portal/portal_server.dart';

void main<T>() async {
  await PortalServer.init(port: 3001, enableLogging: true);

  Isolate.spawn((message) {
    http.post(
      Uri(
          host: "localhost",
          port: 3001,
          scheme: "http",
          path: "/auth/authenticate"),
      headers: {"Authorization": "test_token"},
    );
  }, "");
}

// @Portal("/auth")
// class AuthPortalExample {
//   @AuthInterceptor()
//   @Post("/sign-in")
//   handle(SignUpForm data) {
//     myLogger.d(data);
//     return SignUpResult("jdsonfdksjfnsekjfsj");
//   }
// }
