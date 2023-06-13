import 'package:samba_server/src/extensions/iterable_extension.dart';

import 'constants.dart';
import 'nodes/node.dart';
import 'nodes/predictable_nodes/parametric_node.dart';
import 'nodes/predictable_nodes/predictable_node.dart';
import 'nodes/predictable_nodes/static_node.dart';
import 'nodes/wildcard_node.dart';
import 'route.dart';

class Router {
  final StaticNode _rootNode;

  Router() : _rootNode = StaticNode(kPathSectionDivider);

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
    Node insertNodeInto(Node into, Node node) {
      PredictableNode appendNodeInto(
          List<PredictableNode> into, PredictableNode node) {
        final childNode = into.firstWhereOrNull(
          (childNode) => childNode == node,
        );
        if (childNode != null) {
          // as childNode already present use it directly
          return childNode;
        }
        // as there is no childNode with the pathSection insert it
        into.add(node);
        return node;
      }

      switch (into) {
        case PredictableNode():
          switch (node) {
            case StaticNode():
              return appendNodeInto(
                into.staticNodes ??= [],
                node,
              );
            case ParametricNode():
              switch (node) {
                case RegExpParametricNode():
                  return appendNodeInto(
                    into.regExpParametricNodes ??= [],
                    node,
                  );
                case NonRegExpParametricNode():
                  return appendNodeInto(
                    into.nonRegExpParametricNodes ??= [],
                    node,
                  );
                default:
                  throw UnsupportedError(
                    'Unable to insert into a unknown parametric node',
                  );
              }
            case WildcardNode():
              into.wildcardNode = node;
              return node;
            default:
              throw UnsupportedError(
                'Cannot insert a node into a unsupported node',
              );
          }
        case WildcardNode():
          throw UnsupportedError(
            'Cannot insert a node into a wildcard node. This basically happens when there is an extra pathSections present after the wildcard.',
          );
        default:
          throw UnsupportedError(
            'Cannot insert a node into a unsupported node',
          );
      }
    }

    final pathSections = _sanitizePath(route.path);
    Node currentNode = _rootNode;
    for (final pathSection in pathSections) {
      currentNode = insertNodeInto(currentNode, Node.create(pathSection));
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
    PredictableNode? currentNode, {
    WildcardNode? previouslyMatchedWildcardNode,
  }) {
    if (pathSections.isNotEmpty) {
      // only check for pathSections if its not empty
      PredictableNode? tempNode = currentNode;
      for (int i = 0; i < pathSections.length; ++i) {
        final pathSection = pathSections.elementAt(i);
        // only update the previousWildCardNode if the currentNode's
        // wildcardNode is not null
        if (currentNode?.wildcardNode != null) {
          previouslyMatchedWildcardNode = currentNode?.wildcardNode;
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
                  previouslyMatchedWildcardNode: previouslyMatchedWildcardNode,
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

        // finally assign tempNode to currentNode
        currentNode = tempNode;

        // as there is no node with the pathSection we are looking,
        // simply break the loop without going further
        if (currentNode == null) {
          break;
        }
      }
    }
    // 3. If currentNode is null then try to return the
    // matched wildcard if any
    return (currentNode ?? previouslyMatchedWildcardNode)?.route;
  }

  /// Return all the child routes of a [node]
  Iterable<Route> _getChildRoutesOfNode(Node node) {
    final routes = <Route>[];
    Route? routeToAdd;
    switch (node) {
      case PredictableNode():
        if (node.staticNodes != null) {
          for (final childNode in node.staticNodes!) {
            routeToAdd = childNode.route;
            if (routeToAdd != null) {
              routes.add(routeToAdd);
            }
            routeToAdd = childNode.wildcardNode?.route;
            if (routeToAdd != null) {
              routes.add(routeToAdd);
            }
            routes.addAll(_getChildRoutesOfNode(childNode));
          }
        }

        if (node.regExpParametricNodes != null) {
          for (final childNode in node.regExpParametricNodes!) {
            routeToAdd = childNode.route;
            if (routeToAdd != null) {
              routes.add(routeToAdd);
            }
            routeToAdd = childNode.wildcardNode?.route;
            if (routeToAdd != null) {
              routes.add(routeToAdd);
            }
            routes.addAll(_getChildRoutesOfNode(childNode));
          }
        }

        if (node.nonRegExpParametricNodes != null) {
          for (final childNode in node.nonRegExpParametricNodes!) {
            routeToAdd = childNode.route;
            if (routeToAdd != null) {
              routes.add(routeToAdd);
            }
            routeToAdd = childNode.wildcardNode?.route;
            if (routeToAdd != null) {
              routes.add(routeToAdd);
            }
            routes.addAll(_getChildRoutesOfNode(childNode));
          }
        }
        break;
      default:
        throw UnsupportedError(
          'Unsupported node detected',
        );
    }
    return routes;
  }

  /// Returns all routes inserted into router
  Iterable<Route> get routes {
    final routes = <Route>[];
    StaticNode? currentNode = _rootNode;
    Route? routeToAdd = currentNode.route;
    if (routeToAdd != null) {
      routes.add(routeToAdd);
    }
    routeToAdd = currentNode.wildcardNode?.route;
    if (routeToAdd != null) {
      routes.add(routeToAdd);
    }
    routes.addAll(_getChildRoutesOfNode(_rootNode));
    return routes;
  }
}
