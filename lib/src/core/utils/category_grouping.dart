import '../../models/models.dart';

const uncategorizedCategoryLabel = 'Uncategorized';

class CategoryGroup<T> {
  const CategoryGroup({
    required this.shopId,
    required this.shopName,
    required this.items,
  });

  /// Empty for the fallback "Uncategorized" bucket.
  final String shopId;
  final String shopName;
  final List<T> items;
}

List<CategoryGroup<T>> groupByCategory<T>(
  Iterable<T> items, {
  required String Function(T item) shopIdOf,
  required String Function(T item) shopNameOf,
}) {
  final order = <String>[];
  final buckets = <String, List<T>>{};
  final displayNames = <String, String>{};

  for (final item in items) {
    final shopId = shopIdOf(item).trim();
    final rawName = shopNameOf(item).trim();
    final key = shopId;
    if (!buckets.containsKey(key)) {
      buckets[key] = <T>[];
      displayNames[key] = rawName.isEmpty ? uncategorizedCategoryLabel : rawName;
      order.add(key);
    }
    buckets[key]!.add(item);
  }

  final groups = [
    for (final key in order)
      CategoryGroup<T>(shopId: key, shopName: displayNames[key]!, items: buckets[key]!),
  ];

  groups.sort((a, b) {
    final aUncategorized = a.shopId.isEmpty;
    final bUncategorized = b.shopId.isEmpty;
    if (aUncategorized != bUncategorized) return aUncategorized ? 1 : -1;
    return a.shopName.toLowerCase().compareTo(b.shopName.toLowerCase());
  });

  return groups;
}

extension CartItemCategoryGrouping on List<CartItem> {
  List<CategoryGroup<CartItem>> groupByShop() => groupByCategory(
        this,
        shopIdOf: (item) => item.shopId,
        shopNameOf: (item) => item.shopName,
      );
}

extension ProductCategoryGrouping on List<Product> {
  List<CategoryGroup<Product>> groupByShop() => groupByCategory(
        this,
        shopIdOf: (product) => product.shopId,
        shopNameOf: (product) => product.shopName,
      );
}

extension OrderItemCategoryGrouping on List<OrderItem> {
  List<CategoryGroup<OrderItem>> groupByShop() => groupByCategory(
        this,
        shopIdOf: (item) => item.shopId,
        shopNameOf: (item) => item.shopName,
      );
}

/// Alphabetical by category name, blank/"Uncategorized" last — the same
/// ordering [groupByCategory] uses, but for the already one-entry-per-
/// category photo/manual list arrays, where a full bucket-and-group pass
/// would be pointless.
int _compareByCategory(
  String shopIdA,
  String shopNameA,
  String shopIdB,
  String shopNameB,
) {
  final aUncategorized = shopIdA.trim().isEmpty;
  final bUncategorized = shopIdB.trim().isEmpty;
  if (aUncategorized != bUncategorized) {
    return aUncategorized ? 1 : -1;
  }
  return shopNameA.toLowerCase().compareTo(shopNameB.toLowerCase());
}

extension OrderPhotoListSorting on List<OrderPhotoList> {
  List<OrderPhotoList> sortedByCategory() {
    final sorted = [...this];
    sorted.sort(
      (a, b) => _compareByCategory(a.shopId, a.shopName, b.shopId, b.shopName),
    );
    return sorted;
  }
}

extension OrderManualListSorting on List<OrderManualList> {
  List<OrderManualList> sortedByCategory() {
    final sorted = [...this];
    sorted.sort(
      (a, b) => _compareByCategory(a.shopId, a.shopName, b.shopId, b.shopName),
    );
    return sorted;
  }
}

extension DraftPhotoListSorting on List<DraftPhotoList> {
  List<DraftPhotoList> sortedByCategory() {
    final sorted = [...this];
    sorted.sort(
      (a, b) => _compareByCategory(a.shopId, a.shopName, b.shopId, b.shopName),
    );
    return sorted;
  }
}

extension DraftManualListSorting on List<DraftManualList> {
  List<DraftManualList> sortedByCategory() {
    final sorted = [...this];
    sorted.sort(
      (a, b) => _compareByCategory(a.shopId, a.shopName, b.shopId, b.shopName),
    );
    return sorted;
  }
}
