import 'constants.dart';
import 'route.dart';

class Node {
  final String section;
  Route? route;
  List<Node>? childNodes;

  Node(
    this.section, {
    this.route,
    this.childNodes,
  });

  /// Indicates whether the current node is the root node or not
  bool get isRoot => section == kPathSectionDivider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Node &&
          runtimeType == other.runtimeType &&
          section == other.section;

  @override
  int get hashCode => section.hashCode;
}
