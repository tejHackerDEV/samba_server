import 'package:samba_server/src/extensions/iterable_extension.dart';

import 'constants.dart';
import 'node.dart';
import 'route.dart';

class Router {
  final Node _rootNode;

  Router() : _rootNode = Node(kPathSectionDivider);

  /// Sanitizes the [path] & return the pathSections
  /// that can be used for processing. So Before processing
  /// any path that comes to router, we should sanitize it
  /// first to avoid any issues.
  Iterable<String> _sanitizePath(String path) {
    List<String> pathSections = path.split(kPathSectionDivider);
    for (int i = pathSections.length - 1; i >= 0; --i) {
      if (pathSections[i].isEmpty) {
        pathSections.removeAt(i);
      }
    }
    return pathSections;
  }

  /// Register a new [route]
  void register(Route route) {
    final pathSections = _sanitizePath(route.path);
    Node currentNode = _rootNode;
    for (final pathSection in pathSections) {
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

  /// Lookup for a `route` that has been registered by [path].
  /// <br>
  /// If no `route` is registered with [path] returns `null`.
  Route? lookup(String path) {
    final pathSections = _sanitizePath(path);
    Node? currentNode = _rootNode;
    if (pathSections.isNotEmpty) {
      // only check for pathSections if its not empty
      for (final pathSection in pathSections) {
        currentNode = currentNode?.childNodes?.firstWhereOrNull(
          (childNode) => childNode.section == pathSection,
        );
        // as there is no node with the pathSection we are looking,
        // simply break the loop without going further
        if (currentNode == null) {
          break;
        }
      }
    }
    return currentNode?.route;
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
