import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/core/constants/app_constants.dart';
import 'package:grocerydelivery/src/core/utils/validators.dart';
import 'package:grocerydelivery/src/models/models.dart';

void main() {
  Offer buildOffer({String? tag}) {
    return Offer(
      offerId: 'offer-1',
      title: 'Weekend sale',
      tamilTitle: '',
      caption: '20% off',
      tamilCaption: '',
      imageUrl: 'https://example.com/offer.jpg',
      imagePublicId: 'offer-1',
      createdAt: DateTime(2026, 1, 1),
      isActive: true,
      tag: tag,
    );
  }

  group('Offer.badgeTag fallback', () {
    test('old offer without a tag field falls back to empty (UI shows "New offer")', () {
      final legacyMap = {
        'offerId': 'offer-legacy',
        'title': 'Old offer',
        'caption': 'Still works',
        'imageUrl': 'https://example.com/legacy.jpg',
        'imagePublicId': 'legacy',
        'createdAt': DateTime(2025, 1, 1).toIso8601String(),
        'isActive': true,
        // no 'tag' key at all, like documents written before this feature.
      };
      final offer = Offer.fromMap(legacyMap, 'offer-legacy');

      expect(offer.tag, isNull);
      expect(offer.badgeTag, isEmpty);
      // Rest of the legacy fields must still parse unchanged.
      expect(offer.title, 'Old offer');
      expect(offer.isActive, isTrue);
    });

    test('offer with tag "Ad" displays "Ad"', () {
      expect(buildOffer(tag: 'Ad').badgeTag, 'Ad');
    });

    test('offer with tag "Offer" displays "Offer"', () {
      expect(buildOffer(tag: 'Offer').badgeTag, 'Offer');
    });

    test('custom tag saves and displays exactly as entered', () {
      expect(buildOffer(tag: 'Weekend Special').badgeTag, 'Weekend Special');
    });

    test('blank/whitespace-only tag behaves like no tag', () {
      expect(buildOffer(tag: '   ').badgeTag, isEmpty);
    });

    test('tag is trimmed for display', () {
      expect(buildOffer(tag: '  Hot Deal  ').badgeTag, 'Hot Deal');
    });
  });

  group('Offer tag Firestore round-trip', () {
    test('toMap/fromMap preserves the tag', () {
      final original = buildOffer(tag: 'Sponsored');
      final restored = Offer.fromMap(original.toMap(), original.offerId);

      expect(restored.tag, 'Sponsored');
      expect(restored.badgeTag, 'Sponsored');
    });

    test('toMap writes null tag for offers without one (no forced default)', () {
      final map = buildOffer().toMap();
      expect(map['tag'], isNull);
    });

    test('editing an offer updates the tag independent of other fields', () {
      final created = buildOffer(tag: 'New Offer');
      final edited = Offer(
        offerId: created.offerId,
        title: created.title,
        tamilTitle: created.tamilTitle,
        caption: created.caption,
        tamilCaption: created.tamilCaption,
        imageUrl: created.imageUrl,
        imagePublicId: created.imagePublicId,
        createdAt: created.createdAt,
        isActive: created.isActive,
        tag: 'Limited Time',
      );

      expect(edited.badgeTag, 'Limited Time');
      // Unrelated fields (dates, pricing hooks, activation) stay untouched.
      expect(edited.isActive, created.isActive);
      expect(edited.title, created.title);
    });
  });

  group('AppConstants.offerTags', () {
    test('includes the required preset options', () {
      expect(
        AppConstants.offerTags,
        containsAll(<String>[
          'New Offer',
          'Offer',
          'Ad',
          'Special',
          'Limited Time',
          'Promotion',
        ]),
      );
    });

    test('Custom is the trailing sentinel option', () {
      expect(AppConstants.offerTags.last, AppConstants.offerTagOther);
      expect(AppConstants.offerTagOther, 'Custom');
    });
  });

  group('Validators.offerTag', () {
    test('rejects null', () {
      expect(Validators.offerTag(null), isNotNull);
    });

    test('rejects empty string', () {
      expect(Validators.offerTag(''), isNotNull);
    });

    test('rejects whitespace-only string', () {
      expect(Validators.offerTag('    '), isNotNull);
    });

    test('accepts a normal custom tag', () {
      expect(Validators.offerTag('Hot Deal'), isNull);
    });

    test('accepts a tag exactly at the max length', () {
      final tag = 'A' * AppConstants.offerTagMaxLength;
      expect(Validators.offerTag(tag), isNull);
    });

    test('rejects a tag longer than the max length', () {
      final tooLong = 'A' * (AppConstants.offerTagMaxLength + 1);
      expect(Validators.offerTag(tooLong), isNotNull);
    });
  });
}
