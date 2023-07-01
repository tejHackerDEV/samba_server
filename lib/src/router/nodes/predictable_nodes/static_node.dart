import 'predictable_node.dart';

class StaticNode extends PredictableNode {
  StaticNode(
    super.pathSection, {
    super.route,
    super.staticNodes,
    super.regExpParametricNodes,
    super.nonRegExpParametricNodes,
    super.wildcardNode,
  }) : super(key: pathSection);
}
