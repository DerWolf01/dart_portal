import 'package:portal/portal.dart';
import 'package:portal/portal_server.dart';

void main() async {
  PortalService().registerPortals();
  await PortalServer.init();
}
