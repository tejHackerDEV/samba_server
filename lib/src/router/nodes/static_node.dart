import 'node.dart';

class StaticNode extends Node {
  StaticNode(
    super.pathSection, {
    super.route,
    super.staticNodes,
    super.regExpParametricNodes,
    super.nonRegExpParametricNodes,
    super.wildcardNode,
  });
}
