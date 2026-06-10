// lib/utils/extensions/list_extensions.dart

extension ListExtensions<T> on List<T> {
  /// Replace item at index with new value
  List<T> replaceAt(int index, T newValue) {
    return [...take(index), newValue, ...skip(index + 1)];
  }

  /// Remove item at index
  List<T> removeAt(int index) {
    return [...take(index), ...skip(index + 1)];
  }

  /// Move item from one index to another
  List<T> move(int from, int to) {
    final list = toList();
    final item = list.removeAt(from);
    list.insert(to.clamp(0, list.length), item);
    return list;
  }

  /// Safe get
  T? tryGet(int index) =>
      (index >= 0 && index < length) ? this[index] : null;

  /// Group by a key
  Map<K, List<T>> groupBy<K>(K Function(T) keySelector) {
    final result = <K, List<T>>{};
    for (final item in this) {
      result.putIfAbsent(keySelector(item), () => []).add(item);
    }
    return result;
  }
}
