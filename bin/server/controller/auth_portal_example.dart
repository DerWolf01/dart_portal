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
  Future<bool> preHandle(HttpRequest request) async {
    myLogger.i("pre-handled request $request");
    return true;
  }

  @override
  FutureOr<void> postHandle(
      {required HttpRequest request,
      required SignUpForm portalReceived,
      portalGaveBack}) {
    myLogger.i("post-handled request $request");
  }
}

@Portal("/auth")
class AuthPortalExample {
  @AuthInterceptorExample()
  @Post("/sign-in")
  handle(SignUpForm data) {
    myLogger.i(data);
    return SignUpResult("andsoinewoiwndoenwf1231231231321");
  }

  @Post("/authenticate")
  handleAuthenticate(@HeaderMapping("Authorization") String token) {
    myLogger.i(token);
    return SignUpResult("andsoinewoiwndoenwf1231231231321");
  }
}

class SignUpResult {
  const SignUpResult(this.token);

  final String token;
}
