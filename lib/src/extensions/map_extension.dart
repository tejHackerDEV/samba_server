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
          if (previousValue is! Iterable) {
            return [previousValue, value];
          }
          if (previousValue.length > 2) {
            // only spread the previousValue if the length of it
            // is greater than 0. This is to maintain the consistency
            // fot Iterable values.
            return [...previousValue, value];
          }
          return [previousValue, value];
        },
        ifAbsent: () => value,
      );
}
