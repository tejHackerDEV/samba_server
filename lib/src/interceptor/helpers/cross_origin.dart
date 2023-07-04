import 'dart:async';

import '../../errors.dart';
import '../../helpers/enums/index.dart';
import '../../request.dart';
import '../../response.dart';
import '../../utils/headers.dart';
import '../interceptor.dart';

const _kWildcardOrigin = '*';

class CrossOriginInterceptor extends Interceptor {
  /// Defines the origins that should be allowed
  /// by server.
  ///
  /// Only allows `RegExp/String` types in the values.
  ///
  /// If value is `RegExp` then the incoming origin
  /// will be matched against it.
  /// If value is `String` then normal equality check
  /// will be done.
  final Iterable<Object>? originsToAllow;

  /// Indicates whether we should allow credentials or not
  final bool shouldAllowCredentials;

  /// If this is not null, then sets this value in the response header
  /// by converting into seconds
  final Duration? maxAge;

  /// Whatever [HttpMethod]'s defined in this, will be allowed
  /// to go through `this` middleware to next middleware or route.
  ///
  /// <br>
  /// Else it will return method not allowed as a response.
  final Iterable<HttpMethod> httpMethodsToAllow;

  /// Indicates whether we should block the preflight requests or not.
  final bool shouldBlockPreflight;

  const CrossOriginInterceptor._({
    required this.originsToAllow,
    required this.shouldAllowCredentials,
    required this.maxAge,
    required this.shouldBlockPreflight,
    required this.httpMethodsToAllow,
  });

  factory CrossOriginInterceptor({
    Iterable<Object>? originsToAllow,
    bool shouldAllowCredentials = false,
    Duration? maxAge,
    bool shouldBlockPreflight = true,
    Iterable<HttpMethod>? httpMethodsToAllow,
  }) {
    if (originsToAllow != null) {
      for (final origin in originsToAllow) {
        assert(
          origin is RegExp || origin is String,
          'Origin should be either of type RegExp or String only',
        );
      }
    }
    return CrossOriginInterceptor._(
      originsToAllow: originsToAllow,
      shouldAllowCredentials: shouldAllowCredentials,
      maxAge: maxAge,
      shouldBlockPreflight: shouldBlockPreflight,
      httpMethodsToAllow: httpMethodsToAllow ??
          [
            HttpMethod.get,
            HttpMethod.post,
            HttpMethod.put,
            HttpMethod.patch,
            HttpMethod.delete,
            HttpMethod.options,
          ],
    );
  }

  /// Try to set the allow-origin value to the [headers], only in case
  /// if our server allows the request.
  ///
  /// Returns `true` if set else `false`.
  bool _setAllowOrigin(String? requestOrigin, Map<String, Object> headers) {
    bool shouldAllowOrigin(Object originToAllow, String requestOrigin) {
      if (originToAllow is RegExp) {
        return originToAllow.hasMatch(requestOrigin);
      }
      return originToAllow == requestOrigin;
    }

    String? origin;
    if (originsToAllow == null) {
      // as nothing defined, allow all origins by default
      origin = _kWildcardOrigin;
    } else if (requestOrigin != null) {
      for (final originToAllow in originsToAllow!) {
        // check whether requestOrigin matches with
        // any origin user wants to allow.
        if (shouldAllowOrigin(originToAllow, requestOrigin)) {
          headers[Headers.kVary] = 'Origin';
          origin = requestOrigin;
          break;
        }
      }
    }

    if (origin == null) {
      return false;
    }
    headers[Headers.kAccessControlAllowOrigin] = origin;
    return true;
  }

  /// Only set the value to [headers] if [shouldAllowCredentials]
  /// is true.
  ///
  /// [For Reference](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Credentials#directives)
  void _setAllowCredentials(Map<String, Object> headers) {
    if (shouldAllowCredentials) {
      headers[Headers.kAccessControlAllowCredentials] = shouldAllowCredentials;
    }
  }

  /// Only set the value to [headers] if [maxAge] value is not null.
  void _setMaxAge(Map<String, Object> headers) {
    if (maxAge != null) {
      headers[Headers.kAccessControlMaxAge] = maxAge!.inSeconds;
    }
  }

  /// Set the methods that will allowed by this interceptor
  /// in comma-separated values to [headers]
  ///
  /// [For Reference](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Methods#directives)
  void _setAllowMethods(Map<String, Object> headers) {
    headers[Headers.kAccessControlAllowMethods] = httpMethodsToAllow
        .map(
          (httpMethod) => httpMethod.name.toUpperCase(),
        )
        .join(',');
  }

  @override
  FutureOr<Response?> onInit(Request request) {
    // Check whether we can allow the method or not.
    bool shouldAllowHttpMethod = false;
    for (final httpMethodToAllow in httpMethodsToAllow) {
      shouldAllowHttpMethod = httpMethodToAllow == request.httpMethod;
      if (shouldAllowHttpMethod) {
        break;
      }
    }

    if (!shouldAllowHttpMethod) {
      throw MethodNotAllowedError(request.httpMethod.name.toUpperCase());
    }

    // If httpMethod is HttpMethod.options then check whether
    // we want to proceed processing the preflight requests or not.
    if (request.httpMethod == HttpMethod.options) {
      if (shouldBlockPreflight) {
        return Response.noContent();
      }
    }
    return null;
  }

  @override
  FutureOr<Response> onDispose(Request request, Response response) {
    _setAllowOrigin(request.headers[Headers.kOrigin], response.headers);
    _setAllowCredentials(response.headers);
    if (request.httpMethod == HttpMethod.options) {
      _setAllowMethods(response.headers);
      _setMaxAge(response.headers);
    }
    return response;
  }
}
