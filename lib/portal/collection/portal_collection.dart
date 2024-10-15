import 'package:portal/my_logger.dart';
import 'package:portal/portal/portal_impl.dart';

class PortalCollection {
  Set<PortalMirror> portalMirrors;

  PortalCollection({Set<PortalMirror>? portalMirors})
      : portalMirrors = portalMirors ?? {};

  int get length => portalMirrors.length;
  PortalMirror? operator [](String path) => getByPath(path);

  void operator []=(String path, PortalMirror portalMirror) =>
      add(portalMirror);
  void add(PortalMirror portalMirror) => portalMirrors.add(portalMirror);

  void addAll(Set<PortalMirror> portalMirrors) =>
      this.portalMirrors.addAll(portalMirrors);
  void clear() => portalMirrors.clear();
  bool contains(PortalMirror portalMirror) =>
      portalMirrors.contains(portalMirror);
  PortalMirror? getByPath(String path) => portalMirrors.where((element) {
        myLogger.w("${element.portal.getPath} : $path");
        return element.portal.getPath == path;
      }).firstOrNull;
  bool isEmpty() => portalMirrors.isEmpty;
  bool isNotEmpty() => portalMirrors.isNotEmpty;
  void remove(PortalMirror portalMirror) => portalMirrors.remove(portalMirror);
  void removeUsingPath(String path) =>
      portalMirrors.removeWhere((element) => element.portal.getPath == path);
}
