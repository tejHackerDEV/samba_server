import 'package:samba_server/src/extensions/iterable_extension.dart';

import '../helpers/enums/index.dart';
import 'constants.dart';
import 'extensions/string_extension.dart';
import 'lookup_result.dart';
import 'nodes/node.dart';
import 'nodes/predictable_nodes/parametric_node.dart';
import 'nodes/predictable_nodes/predictable_node.dart';
import 'nodes/predictable_nodes/static_node.dart';
import 'nodes/wildcard_node.dart';
import 'result.dart';
import 'route.dart';
import 'sanitized_path.dart';

class Router {
  /// Holds the rootNode of each `HttpMethod` under their respective key
  final _nodeMap = <HttpMethod, Node>{};

  Router() {
    reset();
  }

  /// Register a new [route]
  void register(Route route) {
    Node insertNodeInto(Node into, Node node) {
      PredictableNode appendNodeInto(
        List<PredictableNode> into,
        PredictableNode node,
      ) {
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

    final pathSections = SanitizedPath(route.path).pathSections;
    Node currentNode = _nodeMap[route.httpMethod]!;
    for (final pathSection in pathSections) {
      currentNode = insertNodeInto(currentNode, Node.create(pathSection));
    }
    currentNode.route = route;
  }

  /// Lookup for a `route` that has been registered by [path]
  /// under the respected [httpMethod].
  /// <br>
  /// If no `route` is registered with [path] returns `null`.
  LookupResult lookup(HttpMethod httpMethod, String path) {
    final sanitizedPath = SanitizedPath(path);
    Result? result = _lookup(
      sanitizedPath.pathSections,
      _nodeMap[httpMethod] as StaticNode,
      pathParameters: {},
    );
    // result is null, so try looking under
    // the all method if possible.
    if (result == null && httpMethod != HttpMethod.all) {
      result = _lookup(
        sanitizedPath.pathSections,
        _nodeMap[HttpMethod.all] as StaticNode,
        pathParameters: {},
      );
    }
    return LookupResult(
      sanitizedPath.queryString?.toQueryParameters() ?? {},
      result,
    );
  }

  /// Lookup for a `route` under the [currentNode]
  /// with the given [pathSections].
  /// <br>
  /// If no `route` is registered then returns `null`.
  Result? _lookup(
    Iterable<String> pathSections,
    PredictableNode? currentNode, {
    required Map<String, String> pathParameters,
  }) {
    if (pathSections.isNotEmpty) {
      // only check for pathSections if its not empty
      final pathSection = pathSections.first;
      // 1. Check under static nodes.
      PredictableNode? tempNode = currentNode?.staticNodes?.firstWhereOrNull(
        (childNode) => childNode.pathSection == pathSection,
      );

      if (tempNode != null) {
        final result = _lookup(
          pathSections.skip(1),
          tempNode,
          pathParameters: {...pathParameters},
        );
        // if the result is not null then return it directly,
        // instead of going further
        if (result != null) {
          return result;
        }
      }

      // 2. If we are here it means we didn't found
      // what we are looking for under static nodes.
      // So check under parametric nodes now.
      {
        Result? lookupUnderParametricNodes(
          Iterable<ParametricNode> parametricNodes, {
          required Map<String, String> pathParameters,
        }) {
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
              pathParameters[parametricNode.key] = pathSection;
              return _lookup(
                pathSections.skip(1),
                parametricNode,
                pathParameters: pathParameters,
              );
            }
          }
          return null;
        }

        // 2.1 Check under regExpNodes first
        if (currentNode?.regExpParametricNodes != null) {
          final result = lookupUnderParametricNodes(
            currentNode!.regExpParametricNodes!,
            pathParameters: {...pathParameters},
          );
          // if the result is not null then return it directly,
          // instead of going further
          if (result != null) {
            return result;
          }
        }

        // 2.2 As we are here it mean no route found under regExpNodes
        // so check under nonRegExpNodes
        if (currentNode?.nonRegExpParametricNodes != null) {
          final result = lookupUnderParametricNodes(
            currentNode!.nonRegExpParametricNodes!,
            pathParameters: {...pathParameters},
          );
          // if the result is not null then return it directly,
          // instead of going further
          if (result != null) {
            return result;
          }
        }
      }

      // 3. If we are here it means we didn't found
      // what we are looking for under parametric nodes.
      // So check under wildcard node now.
      {
        if (currentNode?.wildcardNode?.route != null) {
          pathParameters[kWildcardKey] = pathSections.join('/');
          return Result(
            currentNode!.wildcardNode!.route!,
            pathParameters,
          );
        }
      }

      // if we are here it means there is no other way of going further
      // so simply return null
      return null;
    }

    // If currentNode route is null then return null directly
    if (currentNode?.route == null) {
      return null;
    }
    return Result(currentNode!.route!, pathParameters);
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

  /// Resets the route of a [httpMethod]
  void _reset(HttpMethod httpMethod) {
    _nodeMap[httpMethod] = StaticNode(kPathSectionDivider);
  }

  /// Resets the routes registered.
  ///
  /// <br>
  /// If [httpMethod] is defined then routes only
  /// present in that nodes will be deleted
  void reset([HttpMethod? httpMethod]) {
    if (httpMethod != null) {
      _reset(httpMethod);
      return;
    }
    for (final httpMethod in HttpMethod.values) {
      _reset(httpMethod);
    }
  }

  /// Returns all routes inserted into router
  Iterable<Route> get routes {
    final routes = <Route>[];
    _nodeMap.forEach((key, value) {
      StaticNode currentNode = value as StaticNode;
      Route? routeToAdd = currentNode.route;
      if (routeToAdd != null) {
        routes.add(routeToAdd);
      }
      routeToAdd = currentNode.wildcardNode?.route;
      if (routeToAdd != null) {
        routes.add(routeToAdd);
      }
      routes.addAll(_getChildRoutesOfNode(currentNode));
    });
    return routes;
  }
}
