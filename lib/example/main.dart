import 'dart:isolate';
import 'dart:mirrors';

import 'package:portal/example/server/controller/auth_portal_example.dart';
import 'package:portal/portal.dart';
import 'package:portal/portal_server.dart';
import 'package:http/http.dart' as http;

void main<T>() async {
  PortalService().registerPortals();
  await PortalServer.init(port: 3001);

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
