import 'dart:async';
import 'dart:io';

import '../../sign_up_form.dart';
import 'package:portal/interceptor/intercept.dart';
import 'package:portal/portal/gateway.dart';
import 'package:portal/portal/header_mapping.dart';
import 'package:portal/portal/portal_impl.dart';

class AuthInterceptorExample extends Interceptor<SignUpForm> {
  const AuthInterceptorExample();

  @override
  Future<bool> preHandle(HttpRequest request) async {
    print("pre-handled request $request");
    return true;
  }

  @override
  FutureOr<void> postHandle(
      {required HttpRequest request,
      required SignUpForm portalReceived,
      portalGaveBack}) {
    print("post-handled request $request");
  }
}

@Portal("/auth")
class AuthPortalExample {
  @AuthInterceptorExample()
  @Post("/sign-in")
  handle(SignUpForm data) {
    print(data);
    return SignUpResult("andsoinewoiwndoenwf1231231231321");
  }

  @Post("/authenticate")
  handleAuthenticate(@HeaderMapping("Authorization") String token) {
    print(token);
    return SignUpResult("andsoinewoiwndoenwf1231231231321");
  }
}

class SignUpResult {
  const SignUpResult(this.token);

  final String token;
}
