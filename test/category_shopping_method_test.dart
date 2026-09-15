import 'package:flutter_test/flutter_test.dart';
import 'package:grocerydelivery/src/models/models.dart';
import 'package:grocerydelivery/src/services/firebase_bootstrap.dart';
import 'package:grocerydelivery/src/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('same category cannot mix photo list and item selection', () async {
    final appState = _buildAppState();
    appState.setSelectedHomeCategory(_shop());
    await appState.setBillImagePath('/tmp/vegetables.jpg');

    expect(
      () => appState.addToCart(_product(id: 'tomato')),
      throwsA(isA<CategoryMethodConflictException>()),
    );
  });

  test('different categories can use different shopping methods', () async {
    final appState = _buildAppState();
    appState.setSelectedHomeCategory(_shop(id: 'veg', name: 'Vegetables'));
    await appState.setBillImagePath('/tmp/vegetables.jpg');

    await appState.addToCart(
      _product(id: 'apple', shopId: 'fruit', shopName: 'Fruits'),
    );

    appState.setSelectedHomeCategory(_shop(id: 'pharmacy', name: 'Pharmacy'));
    await appState.setManualListText('Panadol\nVitamins');

    expect(
      appState.selectedMethodForCategory('veg'),
      OrderCategoryMethod.methodPhoto,
    );
    expect(
      appState.selectedMethodForCategory('fruit'),
      OrderCategoryMethod.methodItems,
    );
    expect(
      appState.selectedMethodForCategory('pharmacy'),
      OrderCategoryMethod.methodManual,
    );
  });

  test('order stores category shopping method payload', () {
    final order = _order(
      categories: [
        const OrderCategoryMethod(
          categoryId: 'veg',
          categoryName: 'Vegetables',
          selectedMethod: OrderCategoryMethod.methodPhoto,
          photoList: OrderCategoryPhotoList(
            images: [
              OrderPhotoList(
                shopId: 'veg',
                shopName: 'Vegetables',
                imageUrl: 'https://example.com/veg.jpg',
                imagePublicId: 'veg-public-id',
              ),
            ],
          ),
        ),
      ],
    );

    final restored = OrderModel.fromMap(order.toMap(), order.orderId);

    expect(restored.categories, hasLength(1));
    expect(restored.categories.single.categoryName, 'Vegetables');
    expect(restored.categories.single.selectedMethod,
        OrderCategoryMethod.methodPhoto);
    expect(restored.categories.single.photoList!.images, hasLength(1));
  });

  test('old photo-only order synthesizes a photo category method', () {
    final restored = OrderModel.fromMap(
      _order(uploadedImageUrl: 'https://example.com/list.jpg').toMap()
        ..remove('categories')
        ..remove('photoLists')
        ..remove('manualLists'),
      'order-1',
    );

    expect(restored.categories, hasLength(1));
    expect(restored.categories.single.selectedMethod,
        OrderCategoryMethod.methodPhoto);
  });
}

AppState _buildAppState() => AppState(
      const FirebaseBootstrap(
        isReady: false,
        errorMessage: 'Firebase unavailable in category method test',
      ),
    );

Shop _shop({String id = 'veg', String name = 'Vegetables'}) {
  return Shop(
    shopId: id,
    shopName: name,
    address: '',
    phone: '',
    isActive: true,
    createdAt: DateTime(2026),
  );
}

Product _product({
  required String id,
  String shopId = 'veg',
  String shopName = 'Vegetables',
}) {
  final now = DateTime(2026);
  return Product(
    productId: id,
    shopId: shopId,
    shopName: shopName,
    name: id,
    nameTamil: '',
    category: 'Other',
    description: '',
    descriptionTamil: '',
    price: 600,
    imageUrl: '',
    imagePublicId: '',
    unit: 'piece',
    stockStatus: 'available',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

OrderModel _order({
  String uploadedImageUrl = '',
  List<OrderCategoryMethod> categories = const <OrderCategoryMethod>[],
}) {
  final now = DateTime(2026);
  return OrderModel(
    orderId: 'order-1',
    userId: 'user-1',
    customerName: 'Customer',
    customerPhone: '+94712345678',
    customerAddress: 'Puttalam',
    items: const <OrderItem>[],
    uploadedImageUrl: uploadedImageUrl,
    uploadedImagePublicId: '',
    manualListText: '',
    paymentReceiptImageUrl: '',
    paymentReceiptImagePublicId: '',
    orderNotes: '',
    cartItemsAmount: 0,
    photoListAmount: 0,
    manualListAmount: 0,
    listAmountsReviewed: false,
    subtotal: 0,
    deliveryCharge: 250,
    serviceCharge: 0,
    totalAmount: 250,
    paymentMethod: 'COD',
    paymentStatus: 'pending',
    orderStatus: 'Pending',
    adminNotes: '',
    rejectionReason: '',
    assignedDeliveryBoyId: '',
    assignedDeliveryPerson: '',
    assignedDeliveryPhone: '',
    deliveryRating: 0,
    deliveryReview: '',
    deliveryReviewedAt: null,
    createdAt: now,
    updatedAt: now,
    categories: categories,
  );
}
