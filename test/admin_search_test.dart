import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/core/utils/category_grouping.dart';
import 'package:grocerydelivery/src/core/utils/search_matching.dart';
import 'package:grocerydelivery/src/models/models.dart';

void main() {
  final catalog = [
    _product(name: 'Anchor Milk Powder', unit: '400g'),
    _product(name: 'Areliye Keeri Samba Rice', unit: '5kg'),
    _product(name: 'Areliye Keeri Samba Rice', unit: '1kg'),
    _product(
      name: 'BIC Shaving Blade',
      nameTamil: 'BIC ஷேவிங் பிளேடு',
      unit: 'piece',
    ),
    _product(
      name: 'Panadol',
      shopId: 'pharmacy',
      shopName: 'Pharmacy',
      category: 'Medicine',
      unit: 'card',
    ),
  ];

  group('filterProductsBySearch', () {
    test('a blank query returns everything', () {
      expect(filterProductsBySearch(catalog, ''), hasLength(catalog.length));
      expect(filterProductsBySearch(catalog, '   '), hasLength(catalog.length));
    });

    test('matches on product name, case insensitively', () {
      final matches = filterProductsBySearch(catalog, 'rice');
      expect(matches, hasLength(2));
      expect(
        filterProductsBySearch(catalog, 'ANCHOR').single.name,
        'Anchor Milk Powder',
      );
    });

    test('every term must match, so extra terms narrow the list', () {
      expect(filterProductsBySearch(catalog, 'rice'), hasLength(2));
      expect(filterProductsBySearch(catalog, 'rice 5kg'), hasLength(1));
      expect(filterProductsBySearch(catalog, 'rice 5kg milk'), isEmpty);
    });

    test('matches on the Tamil name', () {
      final matches = filterProductsBySearch(catalog, 'பிளேடு');
      expect(matches.single.name, 'BIC Shaving Blade');
    });

    test('matches on category name and unit', () {
      expect(filterProductsBySearch(catalog, 'pharmacy').single.name, 'Panadol');
      expect(filterProductsBySearch(catalog, 'medicine').single.name, 'Panadol');
      expect(filterProductsBySearch(catalog, 'piece').single.name,
          'BIC Shaving Blade');
    });

    test('an unmatched query returns nothing', () {
      expect(filterProductsBySearch(catalog, 'bicycle'), isEmpty);
    });
  });

  group('matchesAllSearchTerms', () {
    test('no terms matches everything', () {
      expect(matchesAllSearchTerms('anything', searchTerms('')), isTrue);
      expect(matchesAllSearchTerms('anything', searchTerms('   ')), isTrue);
    });

    test('is case insensitive', () {
      expect(matchesAllSearchTerms('John Doe', searchTerms('JOHN')), isTrue);
    });

    test('every term must appear, in any order', () {
      const haystack = 'John Doe +94712345678 Puttalam';
      expect(matchesAllSearchTerms(haystack, searchTerms('john doe')), isTrue);
      expect(matchesAllSearchTerms(haystack, searchTerms('doe john')), isTrue);
      expect(
        matchesAllSearchTerms(haystack, searchTerms('john puttalam')),
        isTrue,
      );
      expect(matchesAllSearchTerms(haystack, searchTerms('john smith')),
          isFalse);
    });

    test('collapses runs of whitespace between terms', () {
      expect(
        matchesAllSearchTerms('John Doe', searchTerms('  john   doe  ')),
        isTrue,
      );
    });
  });

  group('grouping products by category', () {
    test('buckets products under their category, alphabetically', () {
      final groups = catalog.groupByShop();
      expect(groups.map((g) => g.shopName), ['Groceries', 'Pharmacy']);
      expect(groups.first.items, hasLength(4));
      expect(groups.last.items.single.name, 'Panadol');
    });

    test('uncategorized products sort last', () {
      final groups = [
        _product(name: 'Orphan', shopId: '', shopName: ''),
        _product(name: 'Rice'),
      ].groupByShop();
      expect(groups.map((g) => g.shopName),
          ['Groceries', uncategorizedCategoryLabel]);
    });

    test('grouping a filtered list keeps only matching categories', () {
      final groups = filterProductsBySearch(catalog, 'panadol').groupByShop();
      expect(groups, hasLength(1));
      expect(groups.single.shopName, 'Pharmacy');
    });
  });
}

Product _product({
  required String name,
  String nameTamil = '',
  String shopId = 'groceries',
  String shopName = 'Groceries',
  String category = 'Other',
  String unit = 'piece',
}) {
  final now = DateTime(2026);
  return Product(
    productId: '$name-$unit',
    shopId: shopId,
    shopName: shopName,
    name: name,
    nameTamil: nameTamil,
    category: category,
    description: '',
    descriptionTamil: '',
    price: 500,
    imageUrl: '',
    imagePublicId: '',
    unit: unit,
    stockStatus: 'available',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}
