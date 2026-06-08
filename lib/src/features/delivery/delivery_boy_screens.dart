import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

const _deliveryBackground = Color(0xFFF5F8F6);
const _deliverySurface = Color(0xFFFFFFFF);
const _deliveryInk = Color(0xFF13231A);
const _deliveryMuted = Color(0xFF627168);
const _deliveryLine = Color(0xFFDDE8DF);
const _deliveryPrimary = Color(0xFF176B45);
const _deliveryBlue = Color(0xFF356DAA);
const _deliveryWarning = Color(0xFFD88413);

enum _DeliveryOrderBucket { active, history, all }

class DeliveryBoyDashboardScreen extends StatefulWidget {
  const DeliveryBoyDashboardScreen({super.key});

  @override
  State<DeliveryBoyDashboardScreen> createState() =>
      _DeliveryBoyDashboardScreenState();
}

class _DeliveryBoyDashboardScreenState
    extends State<DeliveryBoyDashboardScreen> {
  var _selectedBucket = _DeliveryOrderBucket.active;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;
    if (profile == null) {
      return const Scaffold(
        body: LoadingView(message: 'Loading account...'),
      );
    }

    return Scaffold(
      backgroundColor: _deliveryBackground,
      appBar: AppBar(
        title: const Text('Delivery dashboard'),
        backgroundColor: _deliveryBackground.withOpacity(0.96),
        foregroundColor: _deliveryInk,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: _deliveryLine)),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => appState.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AppRefreshIndicator(
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth >= 720 ? 24.0 : 16.0;
              return StreamBuilder<List<OrderModel>>(
                stream: appState.firestoreService.watchOrdersForDeliveryBoy(
                  profile.uid,
                ),
                builder: (context, snapshot) {
                  final orders = snapshot.data ?? const <OrderModel>[];
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      orders.isEmpty) {
                    return const RefreshableCenteredContent(
                      child: LoadingView(),
                    );
                  }
                  final visibleOrders = _ordersForBucket(orders);
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontal),
                    child: CustomScrollView(
                      physics: appRefreshScrollPhysics,
                      slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 820),
                            child: _DeliveryHistoryFilterBar(
                              selected: _selectedBucket,
                              activeCount: _activeOrders(orders).length,
                              historyCount: _historyOrders(orders).length,
                              allCount: orders.length,
                              onSelected: (bucket) {
                                setState(() => _selectedBucket = bucket);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      if (visibleOrders.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _DeliveryEmptyOrders(
                            bucket: _selectedBucket,
                            hasAnyOrders: orders.isNotEmpty,
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index.isOdd) {
                                return const SizedBox(height: 12);
                              }
                              final order = visibleOrders[index ~/ 2];
                              return Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 820),
                                  child: _DeliveryOrderCard(order: order),
                                ),
                              );
                            },
                            childCount: visibleOrders.length * 2 - 1,
                          ),
                        ),
                      if (visibleOrders.isNotEmpty)
                        const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  List<OrderModel> _ordersForBucket(List<OrderModel> orders) {
    switch (_selectedBucket) {
      case _DeliveryOrderBucket.active:
        return _activeOrders(orders);
      case _DeliveryOrderBucket.history:
        return _historyOrders(orders);
      case _DeliveryOrderBucket.all:
        return orders;
    }
  }

  List<OrderModel> _activeOrders(List<OrderModel> orders) {
    return orders.where((order) => !_isHistoryOrder(order)).toList();
  }

  List<OrderModel> _historyOrders(List<OrderModel> orders) {
    return orders.where(_isHistoryOrder).toList();
  }

  bool _isHistoryOrder(OrderModel order) {
    return order.orderStatus == 'Delivered' ||
        order.orderStatus == 'Cancelled' ||
        order.orderStatus == 'Rejected';
  }
}

class _DeliveryHistoryFilterBar extends StatelessWidget {
  const _DeliveryHistoryFilterBar({
    required this.selected,
    required this.activeCount,
    required this.historyCount,
    required this.allCount,
    required this.onSelected,
  });

  final _DeliveryOrderBucket selected;
  final int activeCount;
  final int historyCount;
  final int allCount;
  final ValueChanged<_DeliveryOrderBucket> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = [
      _DeliveryOrderFilterOption(
        bucket: _DeliveryOrderBucket.active,
        label: 'Active',
        count: activeCount,
        icon: Icons.local_shipping_outlined,
      ),
      _DeliveryOrderFilterOption(
        bucket: _DeliveryOrderBucket.history,
        label: 'History',
        count: historyCount,
        icon: Icons.history,
      ),
      _DeliveryOrderFilterOption(
        bucket: _DeliveryOrderBucket.all,
        label: 'All',
        count: allCount,
        icon: Icons.list_alt_outlined,
      ),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selected == option.bucket;
          return ChoiceChip(
            selected: isSelected,
            onSelected: (_) => onSelected(option.bucket),
            avatar: Icon(
              option.icon,
              size: 16,
              color: isSelected ? Colors.white : _deliveryPrimary,
            ),
            label: Text('${option.label} (${option.count})'),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : _deliveryInk,
              fontWeight: FontWeight.w900,
            ),
            selectedColor: _deliveryPrimary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? _deliveryPrimary : _deliveryLine,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}

class _DeliveryOrderFilterOption {
  const _DeliveryOrderFilterOption({
    required this.bucket,
    required this.label,
    required this.count,
    required this.icon,
  });

  final _DeliveryOrderBucket bucket;
  final String label;
  final int count;
  final IconData icon;
}

class _DeliveryEmptyOrders extends StatelessWidget {
  const _DeliveryEmptyOrders({
    required this.bucket,
    required this.hasAnyOrders,
  });

  final _DeliveryOrderBucket bucket;
  final bool hasAnyOrders;

  @override
  Widget build(BuildContext context) {
    final title = switch (bucket) {
      _DeliveryOrderBucket.active => 'No active deliveries',
      _DeliveryOrderBucket.history => 'No delivery history',
      _DeliveryOrderBucket.all => 'No assigned orders',
    };
    final message = switch (bucket) {
      _DeliveryOrderBucket.active => hasAnyOrders
          ? 'Completed deliveries are saved in History.'
          : 'Assigned deliveries will appear here.',
      _DeliveryOrderBucket.history =>
        'Delivered and closed assigned orders will appear here.',
      _DeliveryOrderBucket.all => 'Assigned deliveries will appear here.',
    };

    return EmptyState(
      icon: bucket == _DeliveryOrderBucket.history
          ? Icons.history
          : Icons.local_shipping_outlined,
      title: title,
      message: message,
    );
  }
}

class _DeliveryOrderCard extends StatefulWidget {
  const _DeliveryOrderCard({
    required this.order,
  });

  final OrderModel order;

  @override
  State<_DeliveryOrderCard> createState() => _DeliveryOrderCardState();
}

class _DeliveryOrderCardState extends State<_DeliveryOrderCard> {
  var _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final canDeliver = order.orderStatus == 'Out for Delivery';
    return _DeliveryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DeliveryIconBadge(
                icon: Icons.receipt_long,
                color: canDeliver ? _deliveryBlue : _deliveryPrimary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _deliveryInk,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${_shortId(order.orderId)} - ${DateFormat.yMMMd().add_jm().format(order.createdAt)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _deliveryMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(status: order.orderStatus),
            ],
          ),
          const Divider(height: 24, color: _deliveryLine),
          _DeliveryInfoRow('Customer phone', order.customerPhone),
          _DeliveryInfoRow('Address', order.customerAddress),
          _DeliveryInfoRow('Payment method', order.paymentMethod),
          _DeliveryInfoRow('Payment', order.paymentStatus),
          if (order.adminNotes.trim().isNotEmpty)
            _DeliveryInfoRow('Admin notes', order.adminNotes.trim()),
          const SizedBox(height: 12),
          _DeliveryAmountBreakdown(order: order),
          const SizedBox(height: 14),
          _DeliveryOrderItems(order: order),
          if (order.effectiveManualListText.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _DeliveryNotice(
              icon: Icons.edit_note,
              message: order.effectiveManualListText.trim(),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchPhone(order.customerPhone),
                  icon: const Icon(Icons.call),
                  label: const Text('Call customer'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canDeliver && !_isSaving ? _markDelivered : null,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_outlined),
                  label: Text(_isSaving ? 'Saving' : 'Delivered'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _markDelivered() async {
    setState(() => _isSaving = true);
    try {
      await context
          .read<AppState>()
          .authService
          .markAssignedOrderDelivered(widget.order.orderId);
      if (mounted) {
        showSnack(context, 'Order marked delivered.');
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

  Future<void> _launchPhone(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _deliverySurface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _deliveryLine),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ),
    );
  }
}

class _DeliveryIconBadge extends StatelessWidget {
  const _DeliveryIconBadge({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _DeliveryAmountBreakdown extends StatelessWidget {
  const _DeliveryAmountBreakdown({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _DeliveryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DeliverySectionTitle(
            icon: Icons.payments_outlined,
            title: 'Amount details',
          ),
          const SizedBox(height: 8),
          _DeliveryAmountRow('Cart items', order.cartItemsAmount.money),
          if (order.hasUpload)
            _DeliveryAmountRow('Photo list items', order.photoListAmount.money),
          if (order.hasManualList)
            _DeliveryAmountRow(
              'Manual list items',
              order.manualListAmount.money,
            ),
          _DeliveryAmountRow('Subtotal', order.subtotal.money),
          _DeliveryAmountRow('Delivery charge', order.deliveryCharge.money),
          _DeliveryAmountRow('Service charge', order.serviceCharge.money),
          const Divider(height: 18, color: _deliveryLine),
          _DeliveryAmountRow(
            'Total amount',
            order.totalAmount.money,
            isStrong: true,
          ),
        ],
      ),
    );
  }
}

class _DeliveryOrderItems extends StatelessWidget {
  const _DeliveryOrderItems({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    if (order.items.isEmpty) {
      return const _DeliveryPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DeliverySectionTitle(
              icon: Icons.shopping_basket_outlined,
              title: 'Order items',
            ),
            SizedBox(height: 8),
            Text(
              'No cart items. Check the attached list details below.',
              style: TextStyle(
                color: _deliveryMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return _DeliveryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DeliverySectionTitle(
            icon: Icons.shopping_basket_outlined,
            title: 'Order items',
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < order.items.length; index++) ...[
            _DeliveryItemRow(item: order.items[index], index: index),
            if (index != order.items.length - 1)
              const Divider(height: 16, color: _deliveryLine),
          ],
        ],
      ),
    );
  }
}

class _DeliveryPanel extends StatelessWidget {
  const _DeliveryPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _deliveryLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

class _DeliverySectionTitle extends StatelessWidget {
  const _DeliverySectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _deliveryPrimary, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _deliveryInk,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeliveryAmountRow extends StatelessWidget {
  const _DeliveryAmountRow(
    this.label,
    this.value, {
    this.isStrong = false,
  });

  final String label;
  final String value;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isStrong ? _deliveryInk : _deliveryMuted,
                fontWeight: isStrong ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isStrong ? _deliveryPrimary : _deliveryInk,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryItemRow extends StatelessWidget {
  const _DeliveryItemRow({
    required this.item,
    required this.index,
  });

  final OrderItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '#${index + 1}',
            style: const TextStyle(
              color: _deliveryMuted,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  color: _deliveryInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${item.quantity} x ${item.price.money} / ${item.unit}',
                style: const TextStyle(
                  color: _deliveryMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          item.lineTotal.money,
          textAlign: TextAlign.end,
          style: const TextStyle(
            color: _deliveryInk,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DeliveryInfoRow extends StatelessWidget {
  const _DeliveryInfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: _deliveryMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _deliveryInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryNotice extends StatelessWidget {
  const _DeliveryNotice({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _deliveryWarning.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _deliveryWarning.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _deliveryWarning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _deliveryInk,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _shortId(String value) {
  if (value.length <= 8) {
    return value;
  }
  return value.substring(0, 8);
}
