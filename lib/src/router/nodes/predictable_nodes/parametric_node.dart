import 'predictable_node.dart';

abstract class ParametricNode extends PredictableNode {
  ParametricNode(
    super.pathSection, {
    required super.key,
    super.route,
    super.staticNodes,
    super.regExpParametricNodes,
    super.nonRegExpParametricNodes,
    super.wildcardNode,
  });

  /// Create appropriate node based on the [pathSection] passed
  static ParametricNode create(String pathSection) {
    /**
     * `pathSection` starts with `{` & ends with `}`,
     * so take care of them while doing `substring` operations on it.
     */
    final regExpDividerIndex = pathSection.indexOf(':');
    if (regExpDividerIndex == -1) {
      // NonRegex
      return NonRegExpParametricNode(
        pathSection,
        key: pathSection.substring(1, pathSection.length - 1),
      );
    }
    // Regex
    return RegExpParametricNode(
      pathSection,
      key: pathSection.substring(1, regExpDividerIndex),
      regExp: RegExp(
        pathSection.substring(
          regExpDividerIndex + 1,
          pathSection.length - 1,
        ),
      ),
    );
  }
}

class RegExpParametricNode extends ParametricNode {
  final RegExp regExp;

  RegExpParametricNode(
    super.pathSection, {
    required super.key,
    required this.regExp,
    super.route,
    super.staticNodes,
    super.regExpParametricNodes,
    super.nonRegExpParametricNodes,
    super.wildcardNode,
  });
}

class NonRegExpParametricNode extends ParametricNode {
  NonRegExpParametricNode(
    super.pathSection, {
    required super.key,
    super.route,
    super.staticNodes,
    super.regExpParametricNodes,
    super.nonRegExpParametricNodes,
    super.wildcardNode,
  });
}
