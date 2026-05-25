import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../services/cloudinary_service.dart';
import '../../../services/image_picker_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile!;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: 'Cart',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
            icon: Badge.count(
              count: appState.cartCount,
              isLabelVisible: appState.cartCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FirebaseSetupBanner(appState: appState),
            Text(
              'Hi ${profile.fullName.split(' ').first}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF66736B)),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _HomeActionTile(
                    icon: Icons.storefront,
                    title: 'Shops',
                    subtitle: 'Choose a partner shop',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ShopListScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HomeActionTile(
                    icon: Icons.receipt_long,
                    title: 'Upload list',
                    subtitle: 'Photo order',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const UploadBillScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SectionTitle(
              title: 'Categories',
              actionLabel: 'All products',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProductListScreen()),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AppConstants.productCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = AppConstants.productCategories[index];
                  return ActionChip(
                    label: Text(category),
                    avatar: const Icon(Icons.category_outlined, size: 18),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductListScreen(category: category),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SectionTitle(
              title: 'Recent products',
              actionLabel: 'View all',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProductListScreen()),
              ),
            ),
            const _RecentProductsGrid(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          final routes = [
            null,
            const OrderHistoryScreen(),
            const SupportScreen(),
            const ProfileScreen(),
          ];
          final route = routes[index];
          if (route != null) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => route));
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Orders'),
          NavigationDestination(
              icon: Icon(Icons.support_agent), label: 'Support'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _RecentProductsGrid extends StatefulWidget {
  const _RecentProductsGrid();

  @override
  State<_RecentProductsGrid> createState() => _RecentProductsGridState();
}

class _RecentProductsGridState extends State<_RecentProductsGrid> {
  late final Stream<List<Product>> _productsStream;

  @override
  void initState() {
    super.initState();
    _productsStream = context.read<AppState>().firestoreService.watchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _DataErrorState(
            message: _friendlyDataError(snapshot.error),
          );
        }
        final products = (snapshot.data ?? const <Product>[]).take(6).toList();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (products.isEmpty) {
          return const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No products yet',
            message: 'Admin can add products from the admin dashboard.',
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        );
      },
    );
  }
}

class _HomeActionTile extends StatelessWidget {
  const _HomeActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  color: Theme.of(context).colorScheme.primary, size: 30),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF66736B), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopListScreen extends StatelessWidget {
  const ShopListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppState>().firestoreService;
    return Scaffold(
      appBar: AppBar(title: const Text('Partner shops')),
      body: StreamBuilder<List<Shop>>(
        stream: store.watchShops(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final shops = snapshot.data ?? const <Shop>[];
          if (shops.isEmpty) {
            return EmptyState(
              icon: Icons.store_mall_directory_outlined,
              title: 'No active shops',
              message: 'Products can still be browsed from the full catalog.',
              action: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProductListScreen()),
                ),
                icon: const Icon(Icons.search),
                label: const Text('Browse catalog'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: shops.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final shop = shops[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.storefront)),
                  title: Text(shop.shopName),
                  subtitle: Text(shop.address),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductListScreen(shop: shop),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.shop, this.category});

  final Shop? shop;
  final String? category;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _search = TextEditingController();
  late final Stream<List<Product>> _productsStream;

  @override
  void initState() {
    super.initState();
    _productsStream = context.read<AppState>().firestoreService.watchProducts(
          shopId: widget.shop?.shopId,
          category: widget.category,
        );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final title = widget.shop?.shopName ?? widget.category ?? 'Products';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Cart',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
            icon: Badge.count(
              count: appState.cartCount,
              isLabelVisible: appState.cartCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Search products',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _DataErrorState(
                    message: _friendlyDataError(snapshot.error),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }
                final query = _search.text.trim().toLowerCase();
                final products = (snapshot.data ?? const <Product>[])
                    .where(
                      (product) =>
                          query.isEmpty ||
                          product.name.toLowerCase().contains(query) ||
                          product.category.toLowerCase().contains(query),
                    )
                    .toList();
                if (products.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'No products found',
                    message: 'Try a different search or category.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DataErrorState extends StatelessWidget {
  const _DataErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Could not load products',
      message: message,
    );
  }
}

String _friendlyDataError(Object? error) {
  final text = error.toString();
  if (text.contains('permission-denied')) {
    return 'Firebase rules blocked product reads. Deploy the latest Firestore rules.';
  }
  if (text.contains('failed-precondition') || text.contains('index')) {
    return 'Firestore needs an index for this product query. The app now uses a simpler product query, so restart and try again.';
  }
  if (text.contains('TimeoutException')) {
    return 'Firestore did not answer in time. Check the device internet connection and Firebase project.';
  }
  return text;
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ProductImage(url: product.imageUrl, radius: 0),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.price.money} / ${product.unit}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: product.isAvailable
                          ? () async {
                              await appState.addToCart(product);
                              if (context.mounted) {
                                showSnack(context, 'Added to cart.');
                              }
                            }
                          : null,
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: Text(product.isAvailable ? 'Add' : 'Unavailable'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url, this.radius = 8});

  final String url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFEAF0EA),
      child: const Icon(Icons.local_grocery_store, size: 42),
    );
    final brokenImage = Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFEAF0EA),
      child: const Icon(Icons.broken_image, size: 42),
    );

    if (url.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: placeholder,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return placeholder;
        },
        errorBuilder: (_, __, ___) => brokenImage,
      ),
    );
  }
}

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 1.2,
            child: ProductImage(url: product.imageUrl),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              StatusChip(
                status: product.isAvailable ? 'Available' : 'Unavailable',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(product.shopName),
          const SizedBox(height: 8),
          Text(
            '${product.price.money} / ${product.unit}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 16),
          Text(product.description.isEmpty
              ? 'No description added.'
              : product.description),
          const SizedBox(height: 24),
          PrimaryActionButton(
            label: product.isAvailable ? 'Add to cart' : 'Unavailable',
            icon: Icons.add_shopping_cart,
            onPressed: product.isAvailable
                ? () async {
                    await context.read<AppState>().addToCart(product);
                    if (context.mounted) {
                      showSnack(context, 'Added to cart.');
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final items = appState.cartItems;
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (items.isEmpty && !appState.hasBillImage)
            EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Add catalog products or upload a shopping list photo.',
              action: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProductListScreen()),
                ),
                icon: const Icon(Icons.search),
                label: const Text('Browse products'),
              ),
            )
          else ...[
            for (final item in items) _CartItemTile(item: item),
            if (appState.hasBillImage) ...[
              _BillImagePreview(path: appState.billImagePath!),
              const SizedBox(height: 10),
              const _AttachedListPriceNotice(),
            ],
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Catalog subtotal',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      appState.cartSubtotal.money,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UploadBillScreen()),
              ),
              icon: const Icon(Icons.upload_file),
              label: Text(appState.hasBillImage
                  ? 'Change bill/list photo'
                  : 'Upload bill/list photo'),
            ),
            const SizedBox(height: 10),
            PrimaryActionButton(
              label: 'Checkout',
              icon: Icons.payments,
              onPressed: items.isNotEmpty || appState.hasBillImage
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CheckoutScreen()),
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ProductImage(url: item.imageUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text('${item.price.money} / ${item.unit}'),
                  Text(item.lineTotal.money),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Decrease',
              onPressed: () => appState.updateCartQuantity(
                item.productId,
                item.quantity - 1,
              ),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('${item.quantity}',
                style: const TextStyle(fontWeight: FontWeight.w900)),
            IconButton(
              tooltip: 'Increase',
              onPressed: () => appState.updateCartQuantity(
                item.productId,
                item.quantity + 1,
              ),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class UploadBillScreen extends StatelessWidget {
  const UploadBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Upload list or bill')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Upload a clear photo of a handwritten list, printed bill, or shop list.',
          ),
          const SizedBox(height: 16),
          if (appState.hasBillImage)
            _BillImagePreview(path: appState.billImagePath!),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrimaryActionButton(
                  label: appState.hasBillImage ? 'Gallery' : 'Choose photo',
                  icon: Icons.photo_library,
                  onPressed: () async {
                    final imageFile = await pickImageFromGallery();
                    if (imageFile == null) {
                      return;
                    }
                    if (!context.mounted) {
                      return;
                    }
                    await appState.setBillImagePath(imageFile.path);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final imageFile = await takePhotoFromCamera();
                    if (imageFile == null) {
                      return;
                    }
                    if (!context.mounted) {
                      return;
                    }
                    await appState.setBillImagePath(imageFile.path);
                  },
                  icon: const Icon(Icons.photo_camera),
                  label: Text(appState.hasBillImage ? 'Retake' : 'Camera'),
                ),
              ),
            ],
          ),
          if (appState.hasBillImage) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => appState.setBillImagePath(null),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove photo'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              ),
              icon: const Icon(Icons.payments),
              label: const Text('Continue to checkout'),
            ),
          ],
        ],
      ),
    );
  }
}

class _BillImagePreview extends StatelessWidget {
  const _BillImagePreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFFEAF0EA),
                child: Center(child: Icon(Icons.broken_image)),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Shopping list image ready for upload.'),
          ),
        ],
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  final _notes = TextEditingController();
  String _paymentMethod = AppConstants.paymentMethodCod;
  String? _receiptImagePath;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile!;
    _name = TextEditingController(text: profile.fullName);
    _phone = TextEditingController(
      text: PhoneUtils.localSriLankanDigits(profile.phone),
    );
    _address = TextEditingController(text: profile.address);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isBankTransfer =
        _paymentMethod == AppConstants.paymentMethodBankTransfer;
    final total = appState.cartSubtotal +
        AppConstants.defaultDeliveryCharge +
        AppConstants.defaultServiceCharge;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment method',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: AppConstants.paymentMethodCod,
                        groupValue: _paymentMethod,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _paymentMethod = value);
                          }
                        },
                        title: const Text('Cash on Delivery'),
                        subtitle: const Text(
                          'Pay by cash when your order is delivered.',
                        ),
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: AppConstants.paymentMethodBankTransfer,
                        groupValue: _paymentMethod,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _paymentMethod = value);
                          }
                        },
                        title: const Text('Bank transfer'),
                        subtitle: const Text(
                          'Transfer to the store account and upload your receipt.',
                        ),
                      ),
                      if (isBankTransfer) ...[
                        const SizedBox(height: 8),
                        const _BankTransferDetails(),
                        const SizedBox(height: 12),
                        _ReceiptUploadSection(
                          imagePath: _receiptImagePath,
                          onGallery: _pickReceiptFromGallery,
                          onCamera: _takeReceiptPhoto,
                          onRemove: () =>
                              setState(() => _receiptImagePath = null),
                        ),
                      ],
                      const Divider(height: 24),
                      _AmountRow('Subtotal', appState.cartSubtotal.money),
                      _AmountRow('Delivery charge',
                          AppConstants.defaultDeliveryCharge.money),
                      _AmountRow('Service charge',
                          AppConstants.defaultServiceCharge.money),
                      if (appState.hasBillImage) ...[
                        const SizedBox(height: 10),
                        const _AttachedListPriceNotice(),
                      ],
                      const Divider(height: 24),
                      _AmountRow('Estimated total', total.money,
                          isStrong: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _name,
                label: 'Customer name',
                validator: (value) =>
                    Validators.requiredText(value, 'Customer name'),
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 12),
              AppPhoneField(
                controller: _phone,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _address,
                label: 'Delivery address',
                validator: (value) =>
                    Validators.requiredText(value, 'Delivery address'),
                maxLines: 3,
                prefixIcon: Icons.home,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _notes,
                label: 'Order notes',
                maxLines: 3,
                prefixIcon: Icons.notes,
              ),
              const SizedBox(height: 18),
              PrimaryActionButton(
                label: isBankTransfer
                    ? 'Place bank transfer order'
                    : 'Place COD order',
                icon:
                    isBankTransfer ? Icons.account_balance : Icons.check_circle,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_paymentMethod == AppConstants.paymentMethodBankTransfer &&
        (_receiptImagePath == null || _receiptImagePath!.isEmpty)) {
      showSnack(context, 'Upload the bank transfer receipt before checkout.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final order = await context.read<AppState>().createOrder(
            customerName: _name.text,
            customerPhone: PhoneUtils.normalizeSriLankanPhone(_phone.text),
            customerAddress: _address.text,
            orderNotes: _notes.text,
            paymentMethod: _paymentMethod,
            paymentReceiptImagePath: _receiptImagePath,
          );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickReceiptFromGallery() async {
    final imageFile = await pickImageFromGallery();
    if (imageFile == null || !mounted) {
      return;
    }
    setState(() => _receiptImagePath = imageFile.path);
  }

  Future<void> _takeReceiptPhoto() async {
    final imageFile = await takePhotoFromCamera();
    if (imageFile == null || !mounted) {
      return;
    }
    setState(() => _receiptImagePath = imageFile.path);
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(this.label, this.value, {this.isStrong = false});

  final String label;
  final String value;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isStrong ? FontWeight.w900 : FontWeight.w500,
      fontSize: isStrong ? 16 : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _AttachedListPriceNotice extends StatelessWidget {
  const _AttachedListPriceNotice();

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFC83A2B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0B1A8)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: danger, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'The prices of attached list items are not calculated in this estimate. Admin will review the photo and update the final bill.',
              style: TextStyle(
                color: danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankTransferDetails extends StatelessWidget {
  const _BankTransferDetails();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE5DD)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfer account',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          _BankDetailRow('Name', AppConstants.bankAccountName),
          _BankDetailRow('Bank', AppConstants.bankName),
          _BankDetailRow('Branch', AppConstants.bankBranch),
          _BankDetailRow('Account number', AppConstants.bankAccountNumber),
        ],
      ),
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  const _BankDetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF66736B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptUploadSection extends StatelessWidget {
  const _ReceiptUploadSection({
    required this.imagePath,
    required this.onGallery,
    required this.onCamera,
    required this.onRemove,
  });

  final String? imagePath;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment receipt',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1.6,
              child: Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFFEAF0EA),
                  child: Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDDE5DD)),
            ),
            child: const Text(
              'Upload the bank slip or transfer screenshot before placing the order.',
              style: TextStyle(color: Color(0xFF66736B)),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library),
                label: Text(hasImage ? 'Change' : 'Gallery'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.photo_camera),
                label: Text(hasImage ? 'Retake' : 'Camera'),
              ),
            ),
          ],
        ),
        if (hasImage) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove receipt'),
          ),
        ],
      ],
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final isBankTransfer =
        order.paymentMethod == AppConstants.paymentMethodBankTransfer;
    return Scaffold(
      appBar: AppBar(title: const Text('Order placed')),
      body: EmptyState(
        icon: Icons.check_circle,
        title: 'Order received',
        message: isBankTransfer
            ? 'Your bank transfer order is pending admin receipt review.'
            : 'Your COD order is pending admin review.',
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderTrackingScreen(orderId: order.orderId),
                ),
              ),
              icon: const Icon(Icons.track_changes),
              label: const Text('Track order'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Back home'),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Order history')),
      body: StreamBuilder<List<OrderModel>>(
        stream:
            appState.firestoreService.watchOrdersForUser(appState.profile!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final orders = snapshot.data ?? const <OrderModel>[];
          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: 'No orders yet',
              message: 'Your order history will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderTile(order: order);
            },
          );
        },
      ),
    );
  }
}

class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Order ${order.orderId.substring(0, 8)}'),
        subtitle: Text(
          '${DateFormat.yMMMd().add_jm().format(order.createdAt)}\n${order.totalAmount.money}',
        ),
        isThreeLine: true,
        trailing: StatusChip(status: order.orderStatus),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: order.orderId),
          ),
        ),
      ),
    );
  }
}

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Order tracking')),
      body: StreamBuilder<OrderModel?>(
        stream: appState.firestoreService.watchOrder(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final order = snapshot.data;
          if (order == null) {
            return const EmptyState(
              icon: Icons.receipt_long,
              title: 'Order not found',
              message: 'This order may have been removed.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order ${order.orderId.substring(0, 8)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          StatusChip(status: order.orderStatus),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Total: ${order.totalAmount.money}'),
                      Text(
                          'Payment: ${order.paymentMethod} (${order.paymentStatus})'),
                      if (order.adminNotes.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text('Admin notes: ${order.adminNotes}'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _TrackingSteps(status: order.orderStatus),
              const SizedBox(height: 16),
              if (order.items.isNotEmpty) ...[
                const SectionTitle(title: 'Items'),
                for (final item in order.items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text(
                        '${item.quantity} x ${item.price.money} / ${item.unit}'),
                    trailing: Text(item.lineTotal.money),
                  ),
              ],
              if (order.hasUpload) ...[
                const SizedBox(height: 12),
                const SectionTitle(title: 'Uploaded list'),
                const _AttachedListPriceNotice(),
                const SizedBox(height: 10),
                AspectRatio(
                  aspectRatio: 1.4,
                  child: ProductImage(url: order.uploadedImageUrl),
                ),
              ],
              if (order.hasPaymentReceipt) ...[
                const SizedBox(height: 12),
                const SectionTitle(title: 'Payment receipt'),
                AspectRatio(
                  aspectRatio: 1.4,
                  child: ProductImage(url: order.paymentReceiptImageUrl),
                ),
              ],
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SupportScreen(
                      initialSubject: 'Order ${order.orderId.substring(0, 8)}',
                    ),
                  ),
                ),
                icon: const Icon(Icons.support_agent),
                label: const Text('Contact admin'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrackingSteps extends StatelessWidget {
  const _TrackingSteps({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    const statuses = AppConstants.customerTrackingStatuses;
    final currentIndex = statuses.indexOf(status);
    final effectiveIndex = currentIndex < 0 ? 0 : currentIndex;
    final isTerminalStatus = status == 'Cancelled' || status == 'Rejected';
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (var i = 0; i < statuses.length; i++)
              Builder(
                builder: (context) {
                  final isCurrent = i == effectiveIndex && currentIndex >= 0;
                  final isComplete = isTerminalStatus
                      ? i == 0 || isCurrent
                      : i <= effectiveIndex;
                  final stepColor = isCurrent
                      ? _currentStepColor(status, primaryColor)
                      : primaryColor;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Icon(
                            isComplete
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isComplete
                                ? stepColor
                                : const Color(0xFFB8C2BB),
                          ),
                          if (i != statuses.length - 1)
                            Container(
                              height: 28,
                              width: 2,
                              color: !isTerminalStatus && i < effectiveIndex
                                  ? primaryColor
                                  : const Color(0xFFDDE5DD),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            statuses[i],
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _currentStepColor(String status, Color fallback) {
    switch (status) {
      case 'Cancelled':
      case 'Rejected':
      case 'Item Unavailable':
        return const Color(0xFFC83A2B);
      case 'Need Clarification':
      case 'Bill Updated':
        return const Color(0xFFB66D00);
      default:
        return fallback;
    }
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final profile = appState.profile!;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<AppNotification>>(
        stream: appState.firestoreService.watchNotifications(
          userId: profile.uid,
          role: profile.role,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final notifications = snapshot.data ?? const <AppNotification>[];
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              title: 'No notifications',
              message: 'Order and support updates will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(notification.title),
                  subtitle: Text(notification.body),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key, this.initialSubject});

  final String? initialSubject;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  var _isCreating = false;

  @override
  void initState() {
    super.initState();
    _subject.text = widget.initialSubject ?? '';
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final profile = appState.profile!;
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  AppTextField(
                    controller: _subject,
                    label: 'Subject',
                    prefixIcon: Icons.subject,
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: _message,
                    label: 'Message',
                    maxLines: 3,
                    prefixIcon: Icons.message,
                  ),
                  const SizedBox(height: 12),
                  PrimaryActionButton(
                    label: 'Create ticket',
                    icon: Icons.add_comment,
                    isLoading: _isCreating,
                    onPressed: _createTicket,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle(title: 'Your tickets'),
          StreamBuilder<List<SupportTicket>>(
            stream: appState.firestoreService.watchTickets(userId: profile.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final tickets = snapshot.data ?? const <SupportTicket>[];
              if (tickets.isEmpty) {
                return const EmptyState(
                  icon: Icons.support_agent,
                  title: 'No support tickets',
                  message: 'Create a ticket when you need help with an order.',
                );
              }
              return Column(
                children: [
                  for (final ticket in tickets)
                    Card(
                      child: ListTile(
                        title: Text(ticket.subject),
                        subtitle: Text(ticket.status),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SupportThreadScreen(ticket: ticket),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createTicket() async {
    if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) {
      showSnack(context, 'Subject and message are required.');
      return;
    }
    setState(() => _isCreating = true);
    try {
      final appState = context.read<AppState>();
      await appState.firestoreService.createSupportTicket(
        user: appState.profile!,
        subject: _subject.text,
        message: _message.text,
      );
      _subject.clear();
      _message.clear();
      if (mounted) {
        showSnack(context, 'Support ticket created.');
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}

class SupportThreadScreen extends StatefulWidget {
  const SupportThreadScreen({super.key, required this.ticket});

  final SupportTicket ticket;

  @override
  State<SupportThreadScreen> createState() => _SupportThreadScreenState();
}

class _SupportThreadScreenState extends State<SupportThreadScreen> {
  final _message = TextEditingController();
  String? _imagePath;
  var _isSending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final profile = appState.profile!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket.subject),
        actions: [
          if (profile.isAdmin && widget.ticket.status != 'closed')
            IconButton(
              tooltip: 'Close ticket',
              onPressed: () async {
                await appState.firestoreService
                    .closeTicket(widget.ticket.ticketId);
                if (context.mounted) {
                  showSnack(context, 'Ticket closed.');
                }
              },
              icon: const Icon(Icons.check_circle_outline),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<SupportMessage>>(
              stream: appState.firestoreService.watchSupportMessages(
                widget.ticket.ticketId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }
                final messages = snapshot.data ?? const <SupportMessage>[];
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == profile.uid;
                    return Align(
                      alignment:
                          isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 310),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMine
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.message,
                              style: TextStyle(
                                color: isMine ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (message.imageUrl.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 140,
                                child: ProductImage(url: message.imageUrl),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Attach image',
                  onPressed: _isSending ? null : _chooseSupportImage,
                  icon: Icon(
                    _imagePath == null ? Icons.image_outlined : Icons.image,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _message,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isSending ? null : _sendMessage,
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_isSending) {
      return;
    }
    if (_message.text.trim().isEmpty && _imagePath == null) {
      return;
    }
    setState(() => _isSending = true);
    try {
      final appState = context.read<AppState>();
      var imageUrl = '';
      if (_imagePath != null) {
        imageUrl = await CloudinaryService.uploadImage(File(_imagePath!));
      }
      await appState.firestoreService.sendSupportMessage(
        ticket: widget.ticket,
        sender: appState.profile!,
        message:
            _message.text.trim().isEmpty ? 'Image attached' : _message.text,
        imageUrl: imageUrl,
      );
      if (mounted) {
        _message.clear();
        setState(() => _imagePath = null);
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _chooseSupportImage() async {
    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(false),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
    );
    if (fromCamera == null) {
      return;
    }

    final imageFile =
        fromCamera ? await takePhotoFromCamera() : await pickImageFromGallery();
    if (!mounted || imageFile == null) {
      return;
    }
    setState(() => _imagePath = imageFile.path);
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile!;
    _name = TextEditingController(text: profile.fullName);
    _address = TextEditingController(text: profile.address);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(profile.fullName),
                  subtitle: Text('${profile.phone}\n${profile.role}'),
                  isThreeLine: true,
                ),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _name,
                label: 'Full name',
                validator: (value) =>
                    Validators.requiredText(value, 'Full name'),
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _address,
                label: 'Delivery address',
                validator: (value) =>
                    Validators.requiredText(value, 'Delivery address'),
                maxLines: 3,
                prefixIcon: Icons.home,
              ),
              const SizedBox(height: 18),
              PrimaryActionButton(
                label: 'Save profile',
                icon: Icons.save,
                isLoading: _isSaving,
                onPressed: _save,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  await appState.logout();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await context.read<AppState>().updateProfile(
            fullName: _name.text,
            address: _address.text,
          );
      if (mounted) {
        showSnack(context, 'Profile updated.');
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
