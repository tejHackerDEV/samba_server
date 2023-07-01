import 'node.dart';

const kWildcardKey = '*';

class WildcardNode extends Node {
  WildcardNode(
    super.pathSection, {
    super.route,
  }) : super(key: kWildcardKey);
}
