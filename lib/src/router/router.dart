import 'package:samba_server/src/extensions/iterable_extension.dart';
import 'package:samba_server/src/router/nodes/static_node.dart';

import 'constants.dart';
import 'nodes/node.dart';
import 'nodes/parametric_node.dart';
import 'nodes/wildcard_node.dart';
import 'route.dart';

class Router {
  final Node _rootNode;

  Router() : _rootNode = Node.create(kPathSectionDivider);

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
      final nodeToInsert = Node.create(pathSection);
      switch (nodeToInsert) {
        case StaticNode():
          currentNode.staticNodes ??= [];
          final childNode = currentNode.staticNodes!.firstWhereOrNull(
            (childNode) => childNode == nodeToInsert,
          );
          if (childNode == null) {
            // as there is no childNode with the pathSection insert it
            currentNode.staticNodes!.add(nodeToInsert);
            currentNode = nodeToInsert;
          } else {
            // as childNode already present use it directly
            currentNode = childNode;
          }
          break;
        case ParametricNode():
          switch (nodeToInsert) {
            case RegExpParametricNode():
              currentNode.regExpParametricNodes ??= [];
              final childNode =
                  currentNode.regExpParametricNodes!.firstWhereOrNull(
                (childNode) => childNode == nodeToInsert,
              );
              if (childNode == null) {
                // as there is no childNode with the pathSection insert it
                currentNode.regExpParametricNodes!.add(nodeToInsert);
                currentNode = nodeToInsert;
              } else {
                // as childNode already present use it directly
                currentNode = childNode;
              }
              break;
            case NonRegExpParametricNode():
              currentNode.nonRegExpParametricNodes ??= [];
              final childNode =
                  currentNode.nonRegExpParametricNodes!.firstWhereOrNull(
                (childNode) => childNode == nodeToInsert,
              );
              if (childNode == null) {
                // as there is no childNode with the pathSection insert it
                currentNode.nonRegExpParametricNodes!.add(nodeToInsert);
                currentNode = nodeToInsert;
              } else {
                // as childNode already present use it directly
                currentNode = childNode;
              }
              break;
            default:
              throw UnsupportedError('Invalid node detected');
          }
          break;
        case WildcardNode():
          currentNode.wildcardNode = nodeToInsert;
          currentNode = nodeToInsert;
          break;
        default:
          throw UnsupportedError('Invalid node detected');
      }
    }
    currentNode.route = route;
  }

  /// Lookup for a `route` that has been registered by [path].
  /// <br>
  /// If no `route` is registered with [path] returns `null`.
  Route? lookup(String path) {
    final pathSections = _sanitizePath(path);
    return _lookup(pathSections, _rootNode);
  }

  /// Lookup for a `route` under the [currentNode]
  /// with the given [pathSections].
  /// <br>
  /// If no `route` is registered then returns `null`.
  Route? _lookup(
    Iterable<String> pathSections,
    Node? currentNode, {
    Node? previousWildCardNode,
  }) {
    if (pathSections.isNotEmpty) {
      // only check for pathSections if its not empty
      Node? tempNode = currentNode;
      for (int i = 0; i < pathSections.length; ++i) {
        final pathSection = pathSections.elementAt(i);
        // only update the previousWildCardNode if the currentNode's
        // wildcardNode is not null
        if (currentNode?.wildcardNode != null) {
          previousWildCardNode = currentNode?.wildcardNode;
        }
        // 1. Check under static nodes.
        tempNode = currentNode?.staticNodes?.firstWhereOrNull(
          (childNode) => childNode.pathSection == pathSection,
        );

        // 2. If tempNode null then check under parametric nodes.
        if (tempNode == null) {
          Route? lookupUnderParametricNodes(
            Iterable<ParametricNode> parametricNodes,
          ) {
            for (final parametricNode in parametricNodes) {
              final bool didPathSectionMatched;
              switch (parametricNode) {
                case NonRegExpParametricNode():
                  didPathSectionMatched = true;
                case RegExpParametricNode():
                  didPathSectionMatched = parametricNode.regExp.hasMatch(
                    pathSection,
                  );
                  break;
                default:
                  throw UnsupportedError('Invalid parametric node detected');
              }

              if (didPathSectionMatched) {
                return _lookup(
                  pathSections.skip(i + 1),
                  parametricNode,
                  previousWildCardNode: previousWildCardNode,
                );
              }
            }
            return null;
          }

          // 1. Check under regExpNodes first
          if (currentNode?.regExpParametricNodes != null) {
            final routeToReturn = lookupUnderParametricNodes(
              currentNode!.regExpParametricNodes!,
            );
            // if the route found then return it directly, instead
            // of going further
            if (routeToReturn != null) {
              return routeToReturn;
            }
          }

          // 2. As we are here it mean no route found under regExpNodes
          // so check under nonRegExpNodes
          if (currentNode?.nonRegExpParametricNodes != null) {
            final routeToReturn = lookupUnderParametricNodes(
              currentNode!.nonRegExpParametricNodes!,
            );
            // if the route found then return it directly, instead
            // of going further
            if (routeToReturn != null) {
              return routeToReturn;
            }
          }
        }

        // 3. If tempNode null then use the wildcard node directly.
        tempNode ??= previousWildCardNode;

        // finally assign tempNode to currentNode
        currentNode = tempNode;

        // as there is no node with the pathSection we are looking,
        // simply break the loop without going further
        if (currentNode == null) {
          break;
        }
      }
    }
    return currentNode?.route;
  }

  /// Return all the child routes of a [node]
  Iterable<Route> _getChildRoutesOfNode(Node node) {
    final routes = <Route>[];
    if (node.staticNodes != null) {
      for (final childNode in node.staticNodes!) {
        Route? routeToAdd = childNode.route;
        if (routeToAdd != null) {
          routes.add(routeToAdd);
        }
        routes.addAll(_getChildRoutesOfNode(childNode));
      }
    }

    if (node.regExpParametricNodes != null) {
      for (final childNode in node.regExpParametricNodes!) {
        Route? routeToAdd = childNode.route;
        if (routeToAdd != null) {
          routes.add(routeToAdd);
        }
        routes.addAll(_getChildRoutesOfNode(childNode));
      }
    }

    if (node.nonRegExpParametricNodes != null) {
      for (final childNode in node.nonRegExpParametricNodes!) {
        Route? routeToAdd = childNode.route;
        if (routeToAdd != null) {
          routes.add(routeToAdd);
        }
        routes.addAll(_getChildRoutesOfNode(childNode));
      }
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
