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

class DeliveryBoyDashboardScreen extends StatelessWidget {
  const DeliveryBoyDashboardScreen({super.key});

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
                  if (orders.isEmpty) {
                    return const RefreshableCenteredContent(
                      child: EmptyState(
                        icon: Icons.local_shipping_outlined,
                        title: 'No assigned orders',
                        message: 'Assigned deliveries will appear here.',
                      ),
                    );
                  }
                  return ListView.separated(
                    physics: appRefreshScrollPhysics,
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      16,
                      horizontal,
                      28,
                    ),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: _DeliveryOrderCard(
                            order: orders[index],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
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
          _DeliveryInfoRow('Amount', order.totalAmount.money),
          _DeliveryInfoRow('Payment', order.paymentStatus),
          if (order.adminNotes.trim().isNotEmpty)
            _DeliveryInfoRow('Admin notes', order.adminNotes.trim()),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Order items',
              style: TextStyle(
                color: _deliveryInk,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in order.items.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '${item.quantity} x ${item.name} - ${item.lineTotal.money}',
                  style: const TextStyle(
                    color: _deliveryMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (order.items.length > 4)
              Text(
                '+${order.items.length - 4} more items',
                style: const TextStyle(
                  color: _deliveryMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
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
