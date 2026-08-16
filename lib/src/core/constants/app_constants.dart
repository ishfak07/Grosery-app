class AppConstants {
  const AppConstants._();

  static const appName = 'Puttalam Drop';
  static const appLogoAsset = 'assets/images/puttalam_drop_logo.png';
  static const packageName = 'com.ishi.grocerydelivery';
  static const currency = 'LKR';
  static const defaultDeliveryCharge = 250.0;
  static const defaultServiceCharge = 0.0;

  /// Minimum eligible product subtotal (before delivery/service charges)
  /// required for a normal catalog cart order to be checked out. Does not
  /// apply to Photo List or Manual List orders. Change this single value to
  /// adjust the minimum order value app-wide.
  static const double minimumOrderValue = 1000;

  /// Formats a rupee amount for customer-facing minimum-order messaging,
  /// e.g. `500` or `180.50`.
  static String formatRupees(double amount) {
    final rounded = amount.roundToDouble();
    final isWhole = (amount - rounded).abs() < 0.005;
    return isWhole ? rounded.toStringAsFixed(0) : amount.toStringAsFixed(2);
  }

  static const paymentMethodCod = 'COD';
  static const paymentMethodBankTransfer = 'Bank Transfer';
  static const bankAccountName = 'Ishfaque mif';
  static const bankName = 'Bank Of Cylon (BOC)';
  static const bankBranch = 'Puttalam';
  static const bankAccountNumber = '89001476';
  static const privacyPolicyUrl = 'https://whatsconnect.sbs/privacy-policy/';
  static const accountDeletionUrl =
      'https://grocery-delivery-app-388bc.web.app/delete-account';

  static const orderStatuses = <String>[
    'Pending',
    'Accepted',
    'Need Clarification',
    'Shopping Started',
    'Item Unavailable',
    'Bill Updated',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
    'Rejected',
  ];

  static const selectableOrderStatuses = <String>[
    'Pending',
    'Accepted',
    'Need Clarification',
    'Shopping Started',
    'Bill Updated',
    'Out for Delivery',
    'Delivered',
    'Rejected',
  ];

  static const customerTrackingStatuses = <String>[
    'Pending',
    'Accepted',
    'Need Clarification',
    'Shopping Started',
    'Bill Updated',
    'Out for Delivery',
    'Delivered',
    'Rejected',
  ];

  /// Terminal/historical order statuses. Once an order reaches one of these
  /// it is a finalized receipt: a later product-catalog price change must
  /// never rewrite it. See [OrderModel.canApplyCurrentProductPrice].
  static const finalizedOrderStatuses = <String>{
    'Delivered',
    'Cancelled',
    'Rejected',
  };

  /// Narrower subset of the non-finalized statuses that get a changed
  /// product price applied AUTOMATICALLY (via the
  /// `syncOrderPricesOnProductPriceChange` Cloud Function) as soon as an
  /// admin saves a new catalog price — no admin action needed. Orders past
  /// this point (Bill Updated/Out for Delivery) keep their price frozen
  /// automatically, since the admin has already finalized the bill or
  /// dispatched the order; they remain reachable only through the manual
  /// "Apply latest prices" admin action. Must be kept in sync with
  /// `functions/lib/orderPriceSync.js`'s `AUTO_SYNC_ORDER_STATUSES` (Dart
  /// and Cloud Functions are separate runtimes and can't share this list
  /// directly). Used for admin UI messaging only — the client never
  /// performs the automatic sync itself.
  static const autoPriceSyncOrderStatuses = <String>{
    'Pending',
    'Accepted',
    'Need Clarification',
    'Shopping Started',
  };

  static const productUnitOther = 'Other';
  static const productUnits = <String>[
    'kg',
    'g',
    'packet',
    'bottle',
    'piece',
    productUnitOther,
  ];

  static const productCategories = <String>[
    'Vegetables',
    'Fruits',
    'Rice & Grains',
    'Dairy',
    'Meat & Fish',
    'Bakery',
    'Beverages',
    'Household',
    'Other',
  ];
}
