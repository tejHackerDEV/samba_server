import 'dart:async';

import '../request.dart';

typedef RouteHandler = FutureOr<Object?> Function(Request request);
