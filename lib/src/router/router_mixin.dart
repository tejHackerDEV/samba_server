import 'route.dart';
import 'router.dart';

/// And helper class that can be used instead of creating the instance
/// of the [Router] class
mixin RouterMixin {
  final Router _router = Router();

  /// Registers a [route]
  void registerRoute(Route route) => _router.register(route);

  /// Return a `route` registered with the [path] provided
  Route? lookupRoute(String path) => _router.lookup(path);
}
