import 'package:portal/portal.dart';
import 'package:portal/portal_example.dart';
import 'package:portal/portal_server.dart';
import 'package:portal/services/collection_service.dart';

void main() async {
  PortalService().registerPortals();
  await PortalServer.init();
}
