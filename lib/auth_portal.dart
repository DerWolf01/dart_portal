import 'package:portal/example/sign_up_form.dart';
import 'package:portal/portal/gateway.dart';
import 'package:portal/portal/portal_impl.dart';

@Portal("/auth")
class AuthPortal {
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
