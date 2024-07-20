import 'dart:async';
import 'dart:io';

import 'package:portal/example/sign_up_form.dart';
import 'package:portal/interceptor/intercept.dart';
import 'package:portal/portal/gateway.dart';
import 'package:portal/portal/portal_impl.dart';

class AuthInterceptor extends Interceptor<SignUpForm> {
  const AuthInterceptor();

  @override
  Future<int> preHandle(HttpRequest request) async {
    print("pre-handled request $request");
    return HttpStatus.ok;
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
class AuthPortal {
  @AuthInterceptor()
  @Post("/sign-in")
  handle(SignUpForm data) {
    print(data);
    return SignUpResult("andsoinewoiwndoenwf1231231231321");
  }
}

class SignUpResult {
  const SignUpResult(this.token);

  final String token;
}
