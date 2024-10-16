// ignore_for_file: unused_import

import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:portal/example/server/controller/auth_portal_example.dart';
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
      headers: {
        "Authorization": "test_token",
        "Content-Type": ContentType.text.mimeType
      },
    );
  }, "");
}
