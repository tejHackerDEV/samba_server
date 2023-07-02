import 'dart:async';

import '../request.dart';
import '../response.dart';

typedef ErrorHandler = FutureOr<Response> Function(
  Request? request,
  Response? response,
  Object error,
  StackTrace stackTrace,
);
