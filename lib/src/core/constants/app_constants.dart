class AppConstants {
  const AppConstants._();

  static const appName = 'Ishi Grocery Delivery';
  static const packageName = 'com.ishi.grocerydelivery';
  static const bootstrapAdminPhone = '+94768976111';
  static const bootstrapAdminPassword = 'admin123';
  static const bootstrapAdminName = 'Admin';
  static const currency = 'LKR';
  static const defaultDeliveryCharge = 250.0;
  static const defaultServiceCharge = 0.0;

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

  static const customerTrackingStatuses = orderStatuses;

  static const productUnits = <String>[
    'kg',
    'g',
    'packet',
    'bottle',
    'piece',
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
