import 'dart:async';

import '../interceptor/index.dart';
import '../request.dart';
import '../response.dart';

typedef ErrorHandler = FutureOr<Response> Function(
  Request? request,
  Response? response,
  Object error,
  StackTrace stackTrace,
);

typedef InterceptorBuilder = FutureOr<Iterable<Interceptor>> Function(
  Request request,
);
