class AppConstants {
  const AppConstants._();

  static const appName = 'Puttalam Drop';
  static const appLogoAsset = 'assets/images/puttalam_drop_logo.png';
  static const packageName = 'com.ishi.grocerydelivery';
  static const bootstrapAdminPhone = '+94768976111';
  static const bootstrapAdminPassword = 'admin123';
  static const bootstrapAdminName = 'Admin';
  static const currency = 'LKR';
  static const defaultDeliveryCharge = 250.0;
  static const defaultServiceCharge = 0.0;
  static const paymentMethodCod = 'COD';
  static const paymentMethodBankTransfer = 'Bank Transfer';
  static const bankAccountName = 'Ishfaque mif';
  static const bankName = 'Bank Of Cylon (BOC)';
  static const bankBranch = 'Puttalam';
  static const bankAccountNumber = '89001476';

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

  static const customerTrackingStatuses = orderStatuses;

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
