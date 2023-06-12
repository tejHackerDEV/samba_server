import 'node.dart';

abstract class ParametricNode extends Node {
  ParametricNode(
    super.pathSection, {
    super.route,
    super.staticNodes,
    super.parametricNodes,
  });

  /// Create appropriate node based on the [pathSection] passed
  static ParametricNode create(String pathSection) {
    final regExpDividerIndex = pathSection.indexOf(':');
    if (regExpDividerIndex == -1) {
      // NonRegex
      return NonRegExpParametricNode(pathSection);
    }
    // Regex
    return RegExpParametricNode(
      pathSection,
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
    required this.regExp,
    super.route,
    super.staticNodes,
    super.parametricNodes,
  });
}

class NonRegExpParametricNode extends ParametricNode {
  NonRegExpParametricNode(
    super.pathSection, {
    super.route,
    super.staticNodes,
    super.parametricNodes,
  });
}
