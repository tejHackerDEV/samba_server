extension IterableExtenion<E> on Iterable<E> {
  /// The first element that satisfies the given predicate [test].
  ///
  /// Iterates through elements and returns the first to satisfy [test].
  ///
  /// Example:
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 5, 6, 7];
  /// var result = numbers.firstWhere((element) => element < 5); // 1
  /// result = numbers.firstWhere((element) => element > 5); // 6
  /// result =
  ///     numbers.firstWhere((element) => element > 10, orElse: () => -1); // -1
  /// ```
  ///
  /// If no element satisfies [test], the result of invoking the [orElse]
  /// function is returned.
  /// If [orElse] is omitted, it defaults to throwing a [StateError].
  E? firstWhereOrNull(
    bool Function(E element) test, {
    E Function()? orElse,
  }) {
    for (E element in this) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    return null;
  }
}
