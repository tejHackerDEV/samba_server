import 'dart:async';

import '../request.dart';
import '../response.dart';

typedef RouteResponse = FutureOr<Response>;
typedef RouteHandler = RouteResponse Function(
  Request request,
  Response response,
);
