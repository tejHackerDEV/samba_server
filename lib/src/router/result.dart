import 'route.dart';

class Result {
  final Route route;
  final Map<String, String> pathParameters;

  Result(this.route, this.pathParameters);
}
