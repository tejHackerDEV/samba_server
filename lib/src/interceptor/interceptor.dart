import 'dart:async';

import '../request.dart';
import '../response.dart';

/// An helper class that will be executed before & after the `RouteHandler`.
/// This is a place where one can modify the [Request] & [Response] attributes,
/// based on their needs
///
/// <br>
/// Returning `null` from [onInit] function will make other [Interceptor]'s
/// after the current interceptor as well as `RouteHandler` to gets executed.
/// If it returns something other than `null` will make other
/// [Interceptor]'s as well as the `RouteHandler` not to be executed.
abstract class Interceptor {
  const Interceptor();

  /// Will get invoked when an interceptor came into execution scope.
  FutureOr<Response?> onInit(Request request) => null;

  /// Will get invoked when an interceptor is going out of the execution scope.
  /// The [response] will hold the value that has been returned
  /// by previous [Interceptor] or [Route].
  ///
  /// <br>
  /// This function will be called in the reverse order
  /// of how the [Interceptor]'s got added to the route.
  ///
  /// <br>
  /// Using this we can even manipulate the response returned
  /// some other [Interceptor]'s or [Route]'s.
  FutureOr<Response> onDispose(Request request, Response response) => response;
}
