import 'dart:async';

import 'package:samba_server/samba_server.dart';

typedef InterceptorOnInitHandler = FutureOr<Response?> Function(
  Request request,
);
typedef InterceptorOnDisposeHandler = FutureOr<Response?> Function(
  Request request,
  Response response,
);

class InterceptorBuilder extends Interceptor {
  final InterceptorOnInitHandler? onInitHandler;
  final InterceptorOnDisposeHandler? onDisposeHandler;

  InterceptorBuilder({
    this.onInitHandler,
    this.onDisposeHandler,
  });

  @override
  FutureOr<Response?> onInit(Request request) => onInitHandler?.call(request);

  @override
  FutureOr<Response> onDispose(Request request, Response response) async {
    return await onDisposeHandler?.call(
          request,
          response,
        ) ??
        response;
  }
}
