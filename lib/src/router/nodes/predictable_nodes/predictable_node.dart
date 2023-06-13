import '../node.dart';
import '../wildcard_node.dart';
import 'parametric_node.dart';
import 'static_node.dart';

abstract class PredictableNode extends Node {
  List<StaticNode>? staticNodes;
  List<RegExpParametricNode>? regExpParametricNodes;
  List<NonRegExpParametricNode>? nonRegExpParametricNodes;
  WildcardNode? wildcardNode;

  PredictableNode(
    super.pathSection, {
    super.route,
    this.staticNodes,
    this.regExpParametricNodes,
    this.nonRegExpParametricNodes,
    this.wildcardNode,
  });

  /// Create appropriate node based on the [pathSection] passed
  static PredictableNode create(String pathSection) {
    if (pathSection[0] == '{' && pathSection[pathSection.length - 1] == '}') {
      // parametric node
      return ParametricNode.create(pathSection);
    }
    // static node
    return StaticNode(pathSection);
  }
}
