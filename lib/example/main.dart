import 'dart:mirrors';

import 'package:portal/portal_server.dart';

void main() async {
  await PortalServer.init(mirrorSystem: currentMirrorSystem());
}
