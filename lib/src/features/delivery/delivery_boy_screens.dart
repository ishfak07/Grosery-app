import 'dart:async';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeRewardStars());
    });
  }

  Future<void> _initializeRewardStars() async {
    try {
      await context.read<AppState>().authService.initializeDeliveryRewardStars();
    } catch (_) {
      // The profile stream will retry naturally after the backend is available.
    }
  }

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
                  final activeOrders = _activeOrders(orders);
                  final historyOrders = _historyOrders(orders);
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
                            child: _DeliveryDashboardHero(
                              deliveryBoyName: profile.fullName,
                              activeCount: activeOrders.length,
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 820),
                            child: _DeliveryRewardCard(profile: profile),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 820),
                            child: _DeliveryPerformanceGrid(orders: orders),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 820),
                            child: _DeliverySectionHeading(
                              bucket: _selectedBucket,
                              count: visibleOrders.length,
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 10)),
                      SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 820),
                            child: _DeliveryHistoryFilterBar(
                              selected: _selectedBucket,
                              activeCount: activeOrders.length,
                              historyCount: historyOrders.length,
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

class _DeliveryRewardCard extends StatelessWidget {
  const _DeliveryRewardCard({required this.profile});

  static const _targetStars = 1000;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final stars = profile.deliveryRewardStars;
    final progress = (stars / _targetStars).clamp(0.0, 1.0).toDouble();
    final remaining = (_targetStars - stars).clamp(0, _targetStars);
    final rewardReady = stars >= _targetStars;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _deliverySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rewardReady
              ? _deliveryWarning.withOpacity(0.55)
              : _deliveryLine,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _deliveryWarning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: _deliveryWarning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LKR 1,000 star reward',
                      style: TextStyle(
                        color: _deliveryInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      rewardReady
                          ? 'LKR $stars is available from your stars'
                          : '$remaining stars until 1,000 stars',
                      style: const TextStyle(
                        color: _deliveryMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$stars / $_targetStars',
                style: const TextStyle(
                  color: _deliveryWarning,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFF1E6D6),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_deliveryWarning),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '1 star = LKR 1. You can ask the admin for a partial or full payment.',
            style: TextStyle(
              color: _deliveryMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (profile.deliveryRewardCount > 0) ...[
            const SizedBox(height: 10),
            Text(
              '${profile.deliveryRewardCount} rewards paid | '
              'LKR ${profile.deliveryRewardsPaidLkr}',
              style: const TextStyle(
                color: _deliveryMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeliveryDashboardHero extends StatelessWidget {
  const _DeliveryDashboardHero({
    required this.deliveryBoyName,
    required this.activeCount,
  });

  final String deliveryBoyName;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final cleanedName = deliveryBoyName.trim();
    final firstName =
        cleanedName.isEmpty ? 'there' : cleanedName.split(RegExp(r'\s+')).first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF176B45), Color(0xFF0F4D33)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _deliveryPrimary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -30,
            child: Icon(
              Icons.local_shipping_outlined,
              size: 126,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: Color(0xFF8CE3B7),
                        ),
                        SizedBox(width: 7),
                        Text(
                          'Ready for delivery',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '$greeting, $firstName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
              ),
              const SizedBox(height: 7),
              Text(
                activeCount == 0
                    ? 'You are all caught up. New assignments will appear here.'
                    : activeCount == 1
                        ? 'You have 1 delivery waiting for you.'
                        : 'You have $activeCount deliveries waiting for you.',
                style: const TextStyle(
                  color: Color(0xFFD9F0E4),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryPerformanceGrid extends StatelessWidget {
  const _DeliveryPerformanceGrid({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final delivered =
        orders.where((order) => order.orderStatus == 'Delivered').toList();
    final reviewed = delivered.where((order) => order.hasDeliveryReview).toList();
    final averageRating = reviewed.isEmpty
        ? 0.0
        : reviewed.fold<int>(
              0,
              (total, order) => total + order.deliveryRating,
            ) /
            reviewed.length;
    final now = DateTime.now();
    final deliveredToday = delivered.where((order) {
      final date = order.updatedAt;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
    final active = orders.where((order) {
      return order.orderStatus != 'Delivered' &&
          order.orderStatus != 'Cancelled' &&
          order.orderStatus != 'Rejected';
    }).length;

    final metrics = [
      _DeliveryMetric(
        label: 'Active now',
        value: '$active',
        icon: Icons.route_outlined,
        color: _deliveryBlue,
      ),
      _DeliveryMetric(
        label: 'Delivered today',
        value: '$deliveredToday',
        icon: Icons.today_outlined,
        color: _deliveryPrimary,
      ),
      _DeliveryMetric(
        label: 'All delivered',
        value: '${delivered.length}',
        icon: Icons.task_alt,
        color: const Color(0xFF6A55A5),
      ),
      _DeliveryMetric(
        label: 'Customer rating',
        value: reviewed.isEmpty ? 'New' : averageRating.toStringAsFixed(1),
        detail: reviewed.isEmpty
            ? 'No reviews yet'
            : '${reviewed.length} ${reviewed.length == 1 ? 'review' : 'reviews'}',
        icon: Icons.star_rounded,
        color: _deliveryWarning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        final width =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _DeliveryMetricCard(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _DeliveryMetric {
  const _DeliveryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.detail,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? detail;
}

class _DeliveryMetricCard extends StatelessWidget {
  const _DeliveryMetricCard({required this.metric});

  final _DeliveryMetric metric;

  @override
  Widget build(BuildContext context) {
    return _DeliveryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DeliveryIconBadge(icon: metric.icon, color: metric.color),
          const SizedBox(height: 12),
          Text(
            metric.value,
            style: const TextStyle(
              color: _deliveryInk,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _deliveryMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (metric.detail != null) ...[
            const SizedBox(height: 2),
            Text(
              metric.detail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: metric.color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeliverySectionHeading extends StatelessWidget {
  const _DeliverySectionHeading({
    required this.bucket,
    required this.count,
  });

  final _DeliveryOrderBucket bucket;
  final int count;

  @override
  Widget build(BuildContext context) {
    final title = switch (bucket) {
      _DeliveryOrderBucket.active => 'Current deliveries',
      _DeliveryOrderBucket.history => 'Delivery history',
      _DeliveryOrderBucket.all => 'All assigned orders',
    };
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _deliveryInk,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _deliveryPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: _deliveryPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
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
          if (order.hasDeliveryReview) ...[
            const SizedBox(height: 12),
            _DeliveryCustomerReview(order: order),
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

class _DeliveryCustomerReview extends StatelessWidget {
  const _DeliveryCustomerReview({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _DeliveryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DeliverySectionTitle(
            icon: Icons.reviews_outlined,
            title: 'Customer review',
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              for (var value = 1; value <= 5; value++)
                Icon(
                  value <= order.deliveryRating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: value <= order.deliveryRating
                      ? _deliveryWarning
                      : _deliveryLine,
                  size: 22,
                ),
              const SizedBox(width: 8),
              Text(
                '${order.deliveryRating}/5',
                style: const TextStyle(
                  color: _deliveryInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (order.deliveryReview.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              order.deliveryReview.trim(),
              style: const TextStyle(
                color: _deliveryMuted,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
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
