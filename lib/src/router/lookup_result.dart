import 'route.dart';

class LookupResult {
  final Route route;
  final Map<String, String> pathParameters;

  LookupResult(this.route, this.pathParameters);

  void addPathParameters(Map<String, String> value) {
    pathParameters.addAll(value);
  }
}
