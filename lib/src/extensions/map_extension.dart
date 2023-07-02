extension MapExtensions on Map<String, dynamic> {
  /// This function will add a new [key] along with the provided [value]
  /// to the [map], if no value present for that [key] in the `map`.
  ///
  /// If a value is already present for that [key] in the `map`,
  /// then its [value] will be converted to a [List] consisting
  /// both previousValue as well as the [value] added into them.
  void addOrUpdateValue({
    required final String key,
    required final dynamic value,
  }) =>
      update(
        key,
        (previousValue) {
          if (previousValue is Iterable) {
            if (previousValue.isNotEmpty) {
              if (previousValue.first is Iterable || value is! Iterable) {
                return [...previousValue, value];
              }
            }
          }
          return [previousValue, value];
        },
        ifAbsent: () => value,
      );
}
