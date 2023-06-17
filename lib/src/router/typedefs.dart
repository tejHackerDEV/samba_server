import 'dart:async';

import '../request.dart';
import '../response.dart';

typedef RouteHandler = FutureOr<Response> Function(
  Request request,
  Response response,
);
