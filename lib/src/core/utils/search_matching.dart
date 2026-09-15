import '../../models/models.dart';

/// Splits a typed query into lowercase search terms, dropping empty ones.
List<String> searchTerms(String query) =>
    query.toLowerCase().split(RegExp(r'\s+'))
      ..removeWhere((term) => term.isEmpty);

/// Whether every term appears somewhere in [haystack].
///
/// Requiring *all* terms is what lets an admin type a full name or
/// "rice 5kg" and have the list narrow, instead of an any-term match
/// widening it or a single substring match failing on word order.
/// No terms means no filter, so everything matches.
bool matchesAllSearchTerms(String haystack, List<String> terms) {
  if (terms.isEmpty) {
    return true;
  }
  final lower = haystack.toLowerCase();
  return terms.every(lower.contains);
}

/// Narrows [products] to those matching [query] on the admin product
/// management screen, across name, Tamil name, category, and unit.
List<Product> filterProductsBySearch(List<Product> products, String query) {
  final terms = searchTerms(query);
  if (terms.isEmpty) {
    return products;
  }
  return products
      .where((product) => matchesAllSearchTerms(
            [
              product.name,
              product.nameTamil,
              product.shopName,
              product.category,
              product.unit,
            ].join(' '),
            terms,
          ))
      .toList();
}
