import 'package:portal/example/sign_up_form.dart';
import 'package:portal/portal.dart';

@Portal("/auth")
class PortalExample {
  @RequestHandler("/sign-up")
  handle(SignUpForm data) {
    print(data);
    return "Hello, World!";
  }
}
