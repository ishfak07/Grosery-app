import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../services/cloudinary_service.dart';
import '../../../services/image_picker_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../customer/customer_screens.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => appState.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FirebaseSetupBanner(appState: appState),
          Text(
            'Hello, ${profile.fullName}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          const Text('Manage orders, products, shops, customers, and support.'),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.08,
            children: [
              _AdminTile(
                icon: Icons.receipt_long,
                title: 'Orders',
                subtitle: 'Review and update',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                ),
              ),
              _AdminTile(
                icon: Icons.inventory_2_outlined,
                title: 'Products',
                subtitle: 'Add, edit, disable',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminProductManagementScreen(),
                  ),
                ),
              ),
              _AdminTile(
                icon: Icons.storefront,
                title: 'Shops',
                subtitle: 'Partner shops',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminShopManagementScreen(),
                  ),
                ),
              ),
              _AdminTile(
                icon: Icons.people_outline,
                title: 'Customers',
                subtitle: 'Block or unblock',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminCustomerManagementScreen(),
                  ),
                ),
              ),
              _AdminTile(
                icon: Icons.support_agent,
                title: 'Support',
                subtitle: 'Reply to tickets',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminSupportScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionTitle(title: 'New orders'),
          StreamBuilder<List<OrderModel>>(
            stream: appState.firestoreService.watchAllOrders(),
            builder: (context, snapshot) {
              final orders = (snapshot.data ?? const <OrderModel>[])
                  .where((order) => order.orderStatus == 'Pending')
                  .take(4)
                  .toList();
              if (orders.isEmpty) {
                return const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No pending orders',
                  message: 'New customer orders will appear here.',
                );
              }
              return Column(
                children: [
                  for (final order in orders) AdminOrderTile(order: order),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
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
                  color: Theme.of(context).colorScheme.primary, size: 32),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
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

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  var _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final filters = [
      'All',
      'Pending',
      'Accepted',
      'Out for Delivery',
      'Delivered'
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = filters[index];
                return ChoiceChip(
                  label: Text(filter),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: appState.firestoreService.watchAllOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }
                final orders = (snapshot.data ?? const <OrderModel>[])
                    .where(
                      (order) =>
                          _filter == 'All' || order.orderStatus == _filter,
                    )
                    .toList();
                if (orders.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long,
                    title: 'No orders',
                    message: 'Orders matching this filter will appear here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return AdminOrderTile(order: orders[index]);
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

class AdminOrderTile extends StatelessWidget {
  const AdminOrderTile({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${order.customerName} - ${order.orderId.substring(0, 8)}'),
        subtitle: Text(
          '${DateFormat.yMMMd().add_jm().format(order.createdAt)}\n${order.totalAmount.money}',
        ),
        isThreeLine: true,
        trailing: StatusChip(status: order.orderStatus),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdminOrderDetailsScreen(orderId: order.orderId),
          ),
        ),
      ),
    );
  }
}

class AdminOrderDetailsScreen extends StatefulWidget {
  const AdminOrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<AdminOrderDetailsScreen> createState() =>
      _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState extends State<AdminOrderDetailsScreen> {
  final _subtotal = TextEditingController();
  final _delivery = TextEditingController();
  final _service = TextEditingController();
  final _adminNotes = TextEditingController();
  final _deliveryPerson = TextEditingController();
  String _status = 'Pending';
  String _paymentStatus = 'pending';
  String? _loadedOrderId;
  var _isSavingBill = false;
  var _isUpdatingStatus = false;

  @override
  void dispose() {
    _subtotal.dispose();
    _delivery.dispose();
    _service.dispose();
    _adminNotes.dispose();
    _deliveryPerson.dispose();
    super.dispose();
  }

  void _syncControllers(OrderModel order) {
    if (_loadedOrderId == order.orderId) {
      return;
    }
    _loadedOrderId = order.orderId;
    _subtotal.text = order.subtotal.toStringAsFixed(2);
    _delivery.text = order.deliveryCharge.toStringAsFixed(2);
    _service.text = order.serviceCharge.toStringAsFixed(2);
    _adminNotes.text = order.adminNotes;
    _deliveryPerson.text = order.assignedDeliveryPerson;
    _status = order.orderStatus;
    _paymentStatus = order.paymentStatus;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: StreamBuilder<OrderModel?>(
        stream: appState.firestoreService.watchOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final order = snapshot.data;
          if (order == null) {
            return const EmptyState(
              icon: Icons.receipt_long,
              title: 'Order not found',
              message: 'This order is no longer available.',
            );
          }
          _syncControllers(order);
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
                              order.customerName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          StatusChip(status: order.orderStatus),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(order.customerPhone),
                      Text(order.customerAddress),
                      if (order.orderNotes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Notes: ${order.orderNotes}'),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _launchPhone(order.customerPhone),
                              icon: const Icon(Icons.call),
                              label: const Text('Call'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _launchWhatsapp(order.customerPhone),
                              icon: const Icon(Icons.chat),
                              label: const Text('WhatsApp'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (order.items.isNotEmpty) ...[
                const SectionTitle(title: 'Items'),
                for (final item in order.items)
                  Card(
                    child: CheckboxListTile(
                      enabled: true,
                      value: item.isAvailable,
                      onChanged: null,
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          color: Color(0xFF17201B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${item.quantity} x ${item.price.money} / ${item.unit}',
                        style: const TextStyle(
                          color: Color(0xFF4B5A51),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      secondary: Text(
                        item.lineTotal.money,
                        style: const TextStyle(
                          color: Color(0xFF4B5A51),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
              if (order.hasUpload) ...[
                const SizedBox(height: 12),
                const SectionTitle(title: 'Uploaded bill/list image'),
                GestureDetector(
                  onTap: () => _showZoomImage(order.uploadedImageUrl),
                  child: AspectRatio(
                    aspectRatio: 1.35,
                    child: ProductImage(url: order.uploadedImageUrl),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextField(
                        controller: _subtotal,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Final subtotal'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _delivery,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Delivery charge'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _service,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Service charge'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _paymentStatus,
                        decoration:
                            const InputDecoration(labelText: 'Payment status'),
                        items: const [
                          DropdownMenuItem(
                              value: 'pending', child: Text('pending')),
                          DropdownMenuItem(
                              value: 'collected', child: Text('collected')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _paymentStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      PrimaryActionButton(
                        label: 'Save bill amount',
                        icon: Icons.save,
                        isLoading: _isSavingBill,
                        onPressed: () => _saveBill(order),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: AppConstants.orderStatuses.contains(_status)
                            ? _status
                            : 'Pending',
                        decoration:
                            const InputDecoration(labelText: 'Order status'),
                        items: AppConstants.orderStatuses
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _deliveryPerson,
                        decoration: const InputDecoration(
                          labelText: 'Assigned delivery person',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _adminNotes,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Admin notes',
                        ),
                      ),
                      const SizedBox(height: 12),
                      PrimaryActionButton(
                        label: 'Update status',
                        icon: Icons.update,
                        isLoading: _isUpdatingStatus,
                        onPressed: () => _updateStatus(order),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveBill(OrderModel order) async {
    setState(() => _isSavingBill = true);
    try {
      final subtotal = double.tryParse(_subtotal.text.trim()) ?? order.subtotal;
      final delivery =
          double.tryParse(_delivery.text.trim()) ?? order.deliveryCharge;
      final service =
          double.tryParse(_service.text.trim()) ?? order.serviceCharge;
      await context.read<AppState>().firestoreService.updateOrderFinancials(
            order: order,
            subtotal: subtotal,
            deliveryCharge: delivery,
            serviceCharge: service,
            paymentStatus: _paymentStatus,
          );
      if (mounted) {
        showSnack(context, 'Bill updated.');
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingBill = false);
      }
    }
  }

  Future<void> _updateStatus(OrderModel order) async {
    setState(() => _isUpdatingStatus = true);
    try {
      await context.read<AppState>().firestoreService.updateOrderStatus(
            order: order,
            status: _status,
            adminNotes: _adminNotes.text,
            assignedDeliveryPerson: _deliveryPerson.text,
          );
      if (mounted) {
        showSnack(context, 'Status updated and notification recorded.');
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _launchWhatsapp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    await launchUrl(Uri.parse('https://wa.me/$digits'));
  }

  void _showZoomImage(String url) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return const SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 280,
                child: Center(child: Icon(Icons.broken_image)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AdminProductManagementScreen extends StatelessWidget {
  const AdminProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Manage products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminProductFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Product'),
      ),
      body: StreamBuilder<List<Product>>(
        stream: appState.firestoreService.watchProducts(activeOnly: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load products',
              message: snapshot.error.toString(),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final products = snapshot.data ?? const <Product>[];
          if (products.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products',
              message: 'Add catalog products for customers to order.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                child: ListTile(
                  leading: SizedBox(
                    width: 52,
                    height: 52,
                    child: ProductImage(url: product.imageUrl),
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.shopName}\n${product.price.money} / ${product.unit}',
                  ),
                  isThreeLine: true,
                  trailing: Switch(
                    value: product.isActive,
                    onChanged: (value) => appState.firestoreService
                        .disableProduct(product.productId, value),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminProductFormScreen(product: product),
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

class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  String _category = AppConstants.productCategories.first;
  String _unit = AppConstants.productUnits.first;
  String _stockStatus = 'available';
  String? _selectedShopId;
  String? _imagePath;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _name.text = product.name;
      _description.text = product.description;
      _price.text = product.price.toStringAsFixed(2);
      _category = product.category;
      _unit = product.unit;
      _stockStatus = product.stockStatus;
      _selectedShopId = product.shopId;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add product' : 'Edit product'),
      ),
      body: StreamBuilder<List<Shop>>(
        stream: appState.firestoreService.watchShops(activeOnly: true),
        builder: (context, snapshot) {
          final shops = _uniqueShops(snapshot.data ?? const <Shop>[]);
          if (_selectedShopId != null &&
              _shopForId(shops, _selectedShopId) == null) {
            _selectedShopId = null;
          }
          _selectedShopId ??= shops.isEmpty ? null : shops.first.shopId;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (shops.isEmpty)
                  const EmptyState(
                    icon: Icons.storefront,
                    title: 'Add a shop first',
                    message: 'Products must be linked to a partner shop.',
                  ),
                AppTextField(
                  controller: _name,
                  label: 'Product name',
                  validator: (value) =>
                      Validators.requiredText(value, 'Product name'),
                  prefixIcon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedShopId,
                  decoration: const InputDecoration(labelText: 'Shop'),
                  items: shops
                      .map(
                        (shop) => DropdownMenuItem(
                          value: shop.shopId,
                          child: Text(shop.shopName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedShopId = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: AppConstants.productCategories.contains(_category)
                      ? _category
                      : AppConstants.productCategories.first,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: AppConstants.productCategories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _description,
                  label: 'Description',
                  maxLines: 3,
                  prefixIcon: Icons.notes,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _price,
                  label: 'Price',
                  validator: (value) {
                    if ((double.tryParse(value ?? '') ?? 0) <= 0) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.payments,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: AppConstants.productUnits
                      .map((unit) =>
                          DropdownMenuItem(value: unit, child: Text(unit)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _unit = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _stockStatus,
                  decoration: const InputDecoration(labelText: 'Stock status'),
                  items: const [
                    DropdownMenuItem(
                        value: 'available', child: Text('available')),
                    DropdownMenuItem(
                      value: 'unavailable',
                      child: Text('unavailable'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _stockStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _pickProductImage(fromCamera: false),
                        icon: const Icon(Icons.image),
                        label: const Text('Gallery'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _pickProductImage(fromCamera: true),
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Camera'),
                      ),
                    ),
                  ],
                ),
                if (_imagePath != null) ...[
                  const SizedBox(height: 8),
                  const Text('Product image selected.'),
                ],
                const SizedBox(height: 18),
                PrimaryActionButton(
                  label: 'Save product',
                  icon: Icons.save,
                  isLoading: _isSaving,
                  onPressed: shops.isEmpty || _isSaving
                      ? null
                      : () => _saveProduct(shops),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveProduct(List<Shop> shops) async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final selectedShop = _shopForId(shops, _selectedShopId);
    if (selectedShop == null) {
      showSnack(context, 'Select a shop.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final appState = context.read<AppState>();
      final productId = widget.product?.productId ?? const Uuid().v4();
      var imageUrl = widget.product?.imageUrl ?? '';
      if (_imagePath != null) {
        imageUrl = await CloudinaryService.uploadImage(File(_imagePath!));
      }
      final now = DateTime.now();
      final product = Product(
        productId: productId,
        shopId: selectedShop.shopId,
        shopName: selectedShop.shopName,
        name: _name.text.trim(),
        category: _category,
        description: _description.text.trim(),
        price: double.parse(_price.text.trim()),
        imageUrl: imageUrl,
        unit: _unit,
        stockStatus: _stockStatus,
        isActive: widget.product?.isActive ?? true,
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );
      await appState.firestoreService.saveProduct(product);
      if (mounted) {
        Navigator.of(context).pop();
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

  Future<void> _pickProductImage({required bool fromCamera}) async {
    final imageFile =
        fromCamera ? await takePhotoFromCamera() : await pickImageFromGallery();
    if (!mounted || imageFile == null) {
      return;
    }
    setState(() => _imagePath = imageFile.path);
  }

  List<Shop> _uniqueShops(List<Shop> shops) {
    final seenIds = <String>{};
    return [
      for (final shop in shops)
        if (seenIds.add(shop.shopId)) shop,
    ];
  }

  Shop? _shopForId(List<Shop> shops, String? shopId) {
    if (shopId == null) {
      return null;
    }
    for (final shop in shops) {
      if (shop.shopId == shopId) {
        return shop;
      }
    }
    return null;
  }
}

class AdminShopManagementScreen extends StatelessWidget {
  const AdminShopManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Manage shops')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showShopDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Shop'),
      ),
      body: StreamBuilder<List<Shop>>(
        stream: appState.firestoreService.watchShops(activeOnly: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final shops = snapshot.data ?? const <Shop>[];
          if (shops.isEmpty) {
            return const EmptyState(
              icon: Icons.storefront,
              title: 'No shops',
              message: 'Add partner shops before adding products.',
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
                  leading: const Icon(Icons.storefront),
                  title: Text(shop.shopName),
                  subtitle: Text('${shop.phone}\n${shop.address}'),
                  isThreeLine: true,
                  trailing: Switch(
                    value: shop.isActive,
                    onChanged: (value) => appState.firestoreService
                        .toggleShop(shop.shopId, value),
                  ),
                  onTap: () => _showShopDialog(context, shop: shop),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showShopDialog(BuildContext context, {Shop? shop}) {
    final name = TextEditingController(text: shop?.shopName ?? '');
    final address = TextEditingController(text: shop?.address ?? '');
    final phone = TextEditingController(text: shop?.phone ?? '');
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(shop == null ? 'Add shop' : 'Edit shop'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Shop name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: address,
                  decoration: const InputDecoration(labelText: 'Address'),
                  minLines: 2,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) {
                  return;
                }
                final appState = context.read<AppState>();
                final saved = Shop(
                  shopId: shop?.shopId ?? const Uuid().v4(),
                  shopName: name.text.trim(),
                  address: address.text.trim(),
                  phone: phone.text.trim(),
                  isActive: shop?.isActive ?? true,
                  createdAt: shop?.createdAt ?? DateTime.now(),
                );
                await appState.firestoreService.saveShop(saved);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Support tickets')),
      body: StreamBuilder<List<SupportTicket>>(
        stream: appState.firestoreService.watchTickets(allTickets: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final tickets = snapshot.data ?? const <SupportTicket>[];
          if (tickets.isEmpty) {
            return const EmptyState(
              icon: Icons.support_agent,
              title: 'No support tickets',
              message: 'Customer messages will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.support_agent),
                  title: Text(ticket.subject),
                  subtitle: Text('${ticket.customerName}\n${ticket.status}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SupportThreadScreen(ticket: ticket),
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

class AdminCustomerManagementScreen extends StatelessWidget {
  const AdminCustomerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: StreamBuilder<List<UserProfile>>(
        stream: appState.firestoreService.watchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final users = snapshot.data ?? const <UserProfile>[];
          if (users.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No customers',
              message: 'Registered users will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(user.fullName.isEmpty ? '?' : user.fullName[0]),
                  ),
                  title: Text(user.fullName),
                  subtitle: Text('${user.phone}\n${user.role}'),
                  isThreeLine: true,
                  trailing: Switch(
                    value: !user.isBlocked,
                    onChanged: user.uid == appState.profile?.uid
                        ? null
                        : (value) => appState.firestoreService.blockUser(
                              user.uid,
                              !value,
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
