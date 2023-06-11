import '../constants.dart';
import '../route.dart';
import 'parametric_node.dart';
import 'static_node.dart';

abstract class Node {
  final String pathSection;
  Route? route;
  List<Node>? childNodes;

  Node(
    this.pathSection, {
    this.route,
    this.childNodes,
  });

  /// Create appropriate node based on the [pathSection] passed
  static Node create(String pathSection) {
    if (pathSection[0] == '{' && pathSection[pathSection.length - 1] == '}') {
      // parametric node
      return ParametricNode(pathSection);
    }
    // static node
    return StaticNode(pathSection);
  }

  /// Indicates whether the current node is the root node or not
  bool get isRoot => pathSection == kPathSectionDivider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Node &&
          runtimeType == other.runtimeType &&
          pathSection == other.pathSection;

  @override
  int get hashCode => pathSection.hashCode;
}