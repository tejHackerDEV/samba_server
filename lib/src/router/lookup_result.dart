import 'result.dart';
import 'route.dart';

class LookupResult {
  final Map<String, dynamic> queryParameters;
  final Result? _result;

  LookupResult(this.queryParameters, this._result);

  Route? get route => _result?.route;

  Map<String, String>? get pathParameters => _result?.pathParameters;
}
