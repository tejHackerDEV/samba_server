import '../constants.dart';
import '../route.dart';
import 'predictable_nodes/predictable_node.dart';
import 'wildcard_node.dart';

abstract class Node {
  final String pathSection;
  Route? route;

  Node(
    this.pathSection, {
    this.route,
  });

  /// Create appropriate node based on the [pathSection] passed
  static Node create(String pathSection) {
    if (pathSection == '*') {
      // wildcard node
      return WildcardNode(pathSection);
    }
    // predictable node
    return PredictableNode.create(pathSection);
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
