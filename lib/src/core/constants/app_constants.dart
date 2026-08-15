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
  static const double minimumOrderValue = 500;

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
