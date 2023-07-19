import 'dart:io' as io;

import 'errors.dart';
import 'interceptor/index.dart';
import 'request.dart';
import 'response.dart';
import 'router/index.dart';
import 'utils/headers.dart';
import 'utils/typedefs.dart';
import 'web_socket/index.dart';

class HttpServer with RouterMixin {
  /// Holds all the [ResponseEncoder]'s that will be used
  /// for encoding all responses body by default, if matched
  /// with any
  final Iterable<ResponseEncoder> _defaultResponseEncoders;

  HttpServer._(this._defaultResponseEncoders);

  /// [shouldEnableDefaultResponseEncoders] if `true` then all
  /// responses body will be encoded by the supported responseEncoder,
  /// if `false` then response will not be encoded by default unless an
  /// [ResponseEncoder] is added explicitly as a [Interceptor].
  factory HttpServer({
    bool shouldEnableDefaultResponseEncoders = true,
  }) {
    final responseEncoders = <ResponseEncoder>[];
    if (shouldEnableDefaultResponseEncoders) {
      responseEncoders.addAll([
        JsonMapResponseEncoder(),
        JsonListResponseEncoder(),
        StringResponseEncoder(),
        NumResponseEncoder(),
        BoolResponseEncoder(),
      ]);
    }
    return HttpServer._(responseEncoders);
  }

  /// Holds the underlying [io.HttpServer] instance.
  io.HttpServer? _ioHttpServer;

  /// Will be invoked every-time, if server gets any runtime exception
  /// while handling any requests.
  ErrorHandler? _globalErrorHandler;

  /// Will holds all the global [Interceptor]'s that will be invoked
  /// for each & every request no matter what.
  Iterable<Interceptor>? _globalInterceptors;

  /// Indicates whether the server is running or not
  bool get isRunning => _ioHttpServer != null;

  /// Returns the uri of the server
  Uri get uri {
    _assertServerRunning();
    final hostBuffer = StringBuffer();
    if (_ioHttpServer!.address.type == io.InternetAddressType.IPv6) {
      // IPv6 addresses in URLs need to be enclosed in square brackets to avoid
      // URL ambiguity with the ":" in the address.
      hostBuffer
        ..write('[')
        ..write(_ioHttpServer!.address.address)
        ..write(']');
    } else {
      hostBuffer.write(_ioHttpServer!.address.address);
    }

    return Uri(
      scheme: 'http',
      host: hostBuffer.toString(),
      port: _ioHttpServer!.port,
    );
  }

  /// Asserts whether the [_ioHttpServer] is not null
  void _assertServerRunning() {
    assert(isRunning, 'Server is not running to perform the action');
  }

  /// Sends the response back to the client based on the [response] passed.
  ///
  /// <br>
  /// After calling this function no one should tamper or try to access
  /// any request or response parameters of this particular request.
  /// As it is useless as well as risky because response is already
  /// passed back to the client. So this should  be the last function
  /// that should be invoked for a particular request.
  Future<void> _sendBackResponse({
    required io.HttpResponse ioHttpResponse,
    required Response response,
  }) async {
    if (response is WebSocketResponse) {
      /**
       * If the response is of type WebSocketResponse,
       * then don't do anything, as things will be already
       * processed by the underlying `io.WebSocket`,
       * so processing again will result in an error
       */
      return;
    }
    ioHttpResponse.statusCode = response.statusCode;
    response.headers.forEach((key, value) {
      ioHttpResponse.headers.set(key, value);
    });
    /**
     * Only write the body, if the statusCode is not equal `noContent`.
     * If its equal then don't write any body & set `content-length` as 0.
     * If we failed to do so, then we get below error.
     *
     * stackTrace
     * ```
     * Unhandled exception:
     * HttpException: Content size exceeds specified contentLength.
     * ```
     */
    if (response.statusCode == io.HttpStatus.noContent) {
      ioHttpResponse.headers.add(Headers.kContentLength, 0);
    } else {
      /**
       * After writing the body don't add or tamper anything
       * because if we failed to do so then we will
       * end up triggering an exception.
       *
       * stackTrace
       * ```
       * Bad state: Header already sent
       * ```
       */
      ioHttpResponse.write(response.body);
    }
    // need to close response to send it back to the client
    return ioHttpResponse.close();
  }

  /// Starts listening for incoming requests
  void _listerForIncomingRequests() {
    _assertServerRunning();
    _ioHttpServer!.listen((ioHttpRequest) async {
      final defaultErrorResponse = Response.internalServerError(
        body: 'Something went wrong, please try again later.',
      );
      try {
        Request? request;
        Response? response;
        final invokedInterceptors = <Interceptor>[];
        try {
          request = Request(ioHttpRequest);
          final lookupResult = lookupRoute(
            request.httpMethod,
            request.completePath,
          );
          request.queryParameters.addAll(lookupResult.queryParameters);
          final route = lookupResult.route;
          if (route == null) {
            // set statusCode as 404 because route not registered
            response = Response.notFound();
          } else {
            // route found so invoke the interceptors & handler.
            if (lookupResult.pathParameters != null) {
              request.pathParameters.addAll(lookupResult.pathParameters!);
            }
            final interceptors = route.interceptors(request);
            // run any global interceptors at first before invoking
            // route's interceptors
            for (final interceptor in [
              ...?_globalInterceptors,
              ...?interceptors,
            ]) {
              response = await interceptor.onInit(request);
              invokedInterceptors.add(interceptor);
              // Don't go further if any interceptor returned response.
              if (response != null) {
                break;
              }
            }
            // only invoke the handler if the response is not set by the interceptors
            response ??= await route.handler(request);
            // invoke the interceptors onDispose in the
            // reverse order they get executed, if request is not null.
            for (int i = invokedInterceptors.length - 1; i >= 0; --i) {
              assert(
                response != null,
                'Response should not be null at this point of time',
              );
              response = await invokedInterceptors.elementAt(i).onDispose(
                    request,
                    response!,
                  );
            }
          }
        } on MethodNotAllowedError catch (error) {
          response = Response.methodNotAllowed(body: error.message);
        } on MethodNotSupportedError catch (error) {
          response = Response.methodNotAllowed(body: error.message);
        } catch (error, stackTrace) {
          response = await _globalErrorHandler?.call(
                request,
                response,
                error,
                stackTrace,
              ) ??
              defaultErrorResponse;
        }
        if (request != null) {
          // only encode response if the request is not null
          for (final responseEncoder in _defaultResponseEncoders) {
            response = await responseEncoder.onDispose(request, response!);
          }
        }
        return _sendBackResponse(
          ioHttpResponse: ioHttpRequest.response,
          response: response!,
        );
      } catch (error) {
        // if we reached here it means something bad has happened
        // & user error handling also failed, so send default error.
        return _sendBackResponse(
          ioHttpResponse: ioHttpRequest.response,
          response: defaultErrorResponse,
        );
      }
    });
  }

  /// Internally calls [io.HttpServer.bind] & all the arguments passed
  /// to this function are the one exposed by [io.HttpServer.bind] function.
  Future<void> bind({
    required dynamic address,
    required int port,
    int backlog = 0,
    bool v6Only = false,
    bool shared = false,
  }) async {
    if (isRunning) {
      throw AssertionError(
        'Server is already bind to port ${_ioHttpServer!.port}. So cant bind it again to port $port',
      );
    }
    _ioHttpServer = await io.HttpServer.bind(
      address,
      port,
      backlog: backlog,
      v6Only: v6Only,
      shared: shared,
    );
    _listerForIncomingRequests();
  }

  /// Adds an global [errorHandler] to the server.
  /// If any uncaught exceptions occurs while handling requests
  /// this will be invoked by the server.
  void addErrorHandler(ErrorHandler errorHandler) {
    if (_globalErrorHandler != null) {
      throw AssertionError(
        'A GlobalErrorHandler is already registered, so can\'t add one more',
      );
    }
    _globalErrorHandler = errorHandler;
  }

  void addInterceptors(Iterable<Interceptor> globalInterceptors) {
    if (_globalInterceptors != null) {
      throw AssertionError(
        'GlobalInterceptors were already registered, so can\'t add one more',
      );
    }
    _globalInterceptors = globalInterceptors;
  }

  /// Permanently stops this [HttpServer] from listening for new
  /// connections. This closes the [Stream] of [HttpRequest]s with a
  /// done event. The returned future completes when the server is
  /// stopped. For a server started using [bind] or [bindSecure] this
  /// means that the port listened on no longer in use.
  ///
  /// If [gracefully] is `false`, active connections will be closed immediately.
  Future<void> shutdown({bool gracefully = true}) async {
    _assertServerRunning();
    await _ioHttpServer?.close(force: gracefully);
    resetRoutes();
    _globalInterceptors = null;
    _globalErrorHandler = null;
    _ioHttpServer = null;
  }
}
