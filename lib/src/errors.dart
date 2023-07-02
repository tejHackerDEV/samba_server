/// A base class that should be extended by all custom errors
/// thrown by SambaServer library.
abstract class SambaServerError {
  final String message;

  SambaServerError(this.message);

  @override
  String toString() => 'SambaServerError: $message';
}

class MethodNotSupportedError extends SambaServerError {
  final String methodName;

  MethodNotSupportedError(this.methodName)
      : super(
          '$methodName method is not supported',
        );
}

class MethodNotAllowedError extends SambaServerError {
  final String methodName;

  MethodNotAllowedError(this.methodName)
      : super(
          '$methodName method is not allowed',
        );
}
