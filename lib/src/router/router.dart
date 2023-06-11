import 'package:samba_server/src/extensions/iterable_extension.dart';

import 'constants.dart';
import 'node.dart';
import 'route.dart';

class Router {
  final Node _rootNode;

  Router() : _rootNode = Node(kPathSectionDivider);

  /// Register a new [route]
  void register(Route route) {
    final pathSections = route.path.split(kPathSectionDivider);
    Node currentNode = _rootNode;
    for (final pathSection in pathSections) {
      if (pathSection.isEmpty) {
        continue;
      }
      final nodeToInsert = Node(pathSection);
      currentNode.childNodes ??= [];
      final childNode = currentNode.childNodes!
          .firstWhereOrNull((childNode) => childNode == nodeToInsert);
      if (childNode == null) {
        // as there is no childNode with the pathSection insert it
        currentNode.childNodes!.add(nodeToInsert);
        currentNode = nodeToInsert;
      } else {
        // as childNode already present use it directly
        currentNode = childNode;
      }
    }
    currentNode.route = route;
  }

  /// Return all the child [Route]'s of a [node]
  Iterable<Route> _getChildRoutesOfNode(Node node) {
    final routes = <Route>[];
    if (node.childNodes == null) {
      return routes;
    }
    for (final childNode in node.childNodes!) {
      Route? routeToAdd = childNode.route;
      if (routeToAdd != null) {
        routes.add(routeToAdd);
      }
      routes.addAll(_getChildRoutesOfNode(childNode));
    }
    return routes;
  }

  /// Returns all routes inserted into router
  Iterable<Route> get routes {
    final routes = <Route>[];
    Node? currentNode = _rootNode;
    Route? routeToAdd = currentNode.route;
    if (routeToAdd != null) {
      routes.add(routeToAdd);
    }
    routes.addAll(_getChildRoutesOfNode(_rootNode));
    return routes;
  }
}
