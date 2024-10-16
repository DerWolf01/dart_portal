import 'dart:async';
import 'dart:io';

import 'package:portal/example/sign_up_form.dart';
import 'package:portal/interceptor/intercept.dart';
import 'package:portal/my_logger.dart';
import 'package:portal/portal/gateway.dart';
import 'package:portal/portal/mappings/header_mapping.dart';
import 'package:portal/portal/portal_impl.dart';

class AuthInterceptorExample extends Interceptor<SignUpForm> {
  const AuthInterceptorExample();

  @override
  FutureOr<void> postHandle(
      {required HttpRequest request,
      required SignUpForm portalReceived,
      portalGaveBack}) {
    myLogger.d("post-handled request $request");
  }

  @override
  Future<bool> preHandle(HttpRequest request) async {
    myLogger.d("pre-handled request $request");
    return true;
  }
}

@Portal("/auth")
class AuthPortalExample {
  @AuthInterceptorExample()
  @Post("/sign-in")
  handle(SignUpForm data) {
    myLogger.d(data);
    return SignUpResult("andsoinewoiwndoenwf1231231231321");
  }

  @Post("/authenticate")
  handleAuthenticate(@HeaderMapping("Authorization") String token) {
    myLogger.d("Token: \"$token\"", header: "AuthPortalExample");
    return SignUpResult("andsoinewoiwndoenwf1231231231321");
  }
}

class SignUpResult {
  final String token;

  const SignUpResult(this.token);
}
