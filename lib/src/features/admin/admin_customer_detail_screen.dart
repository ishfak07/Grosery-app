import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_screens.dart';

const _detailBackground = Color(0xFFF4F7F4);
const _detailSurface = Color(0xFFFFFFFF);
const _detailInk = Color(0xFF14231C);
const _detailMuted = Color(0xFF627168);
const _detailLine = Color(0xFFDDE8DF);
const _detailPrimary = Color(0xFF176B45);
const _detailDanger = Color(0xFFC83A2B);
const _detailWarning = Color(0xFFD88413);
const _detailBlue = Color(0xFF356DAA);

Color _orderStatusColor(String status) {
  switch (status) {
    case 'Delivered':
      return _detailPrimary;
    case 'Cancelled':
    case 'Rejected':
      return _detailDanger;
    case 'Pending':
    case 'Need Clarification':
    case 'Bill Updated':
      return _detailWarning;
    case 'Accepted':
    case 'Out for Delivery':
      return _detailBlue;
    default:
      return _detailMuted;
  }
}

String _money(double amount) => 'LKR ${amount.toStringAsFixed(2)}';

class AdminCustomerDetailScreen extends StatefulWidget {
  const AdminCustomerDetailScreen({super.key, required this.customer});

  final UserProfile customer;

  @override
  State<AdminCustomerDetailScreen> createState() =>
      _AdminCustomerDetailScreenState();
}

class _AdminCustomerDetailScreenState
    extends State<AdminCustomerDetailScreen> {
  final _noteController = TextEditingController();
  var _isSavingNote = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addNote(AppState appState) async {
    final text = _noteController.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => _isSavingNote = true);
    try {
      final admin = appState.profile;
      await appState.firestoreService.addCustomerNote(
        CustomerNote(
          id: const Uuid().v4(),
          customerId: widget.customer.uid,
          text: text,
          createdAt: DateTime.now(),
          createdByUid: admin?.uid ?? '',
          createdByName: admin?.fullName ?? 'Admin',
        ),
      );
      _noteController.clear();
    } catch (error) {
      if (mounted) {
        showSnack(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingNote = false);
      }
    }
  }

  Future<void> _deleteNote(AppState appState, CustomerNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await appState.firestoreService.deleteCustomerNote(note.id);
    } catch (error) {
      if (mounted) {
        showSnack(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final customer = widget.customer;
    return Scaffold(
      backgroundColor: _detailBackground,
      appBar: AppBar(
        title: Text(
          customer.fullName.isEmpty ? 'Customer' : customer.fullName,
          style: const TextStyle(
            color: _detailInk,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: _detailBackground,
        foregroundColor: _detailInk,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        physics: appRefreshScrollPhysics,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: [
          const _SectionHeader(title: 'Account information'),
          const SizedBox(height: 10),
          _AccountInfoCard(customer: customer, appState: appState),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Order summary'),
          const SizedBox(height: 10),
          StreamBuilder<List<OrderModel>>(
            stream: appState.firestoreService.watchOrdersForUser(
              customer.uid,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _DetailCard(child: LoadingView());
              }
              final orders = snapshot.data ?? const <OrderModel>[];
              final totalSpending = orders
                  .where((order) => order.orderStatus == 'Delivered')
                  .fold<double>(0, (sum, order) => sum + order.totalAmount);
              return Column(
                children: [
                  _StatsRow(
                    totalOrders: orders.length,
                    totalSpending: totalSpending,
                  ),
                  const SizedBox(height: 16),
                  const _SectionHeader(title: 'Order history'),
                  const SizedBox(height: 10),
                  if (orders.isEmpty)
                    const _DetailCard(
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No orders yet',
                        message: 'Orders placed by this customer will '
                            'appear here.',
                      ),
                    )
                  else
                    ...orders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OrderHistoryTile(order: order),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Notes'),
          const SizedBox(height: 4),
          const Text(
            'Only visible to admins.',
            style: TextStyle(
              color: _detailMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          _DetailCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Add a note, remark, or business detail about '
                        'this customer',
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingNote ? null : () => _addNote(appState),
                    icon: _isSavingNote
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Add note'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<CustomerNote>>(
            stream: appState.firestoreService.watchCustomerNotes(
              customer.uid,
            ),
            builder: (context, snapshot) {
              final notes = snapshot.data ?? const <CustomerNote>[];
              if (notes.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: notes
                    .map(
                      (note) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NoteTile(
                          note: note,
                          onDelete: () => _deleteNote(appState, note),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _detailInk,
        fontWeight: FontWeight.w900,
        fontSize: 15,
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    return Material(
      color: _detailSurface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: _detailLine),
            borderRadius: radius,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.customer, required this.appState});

  final UserProfile customer;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final joined = DateFormat('dd MMM yyyy').format(customer.createdAt);
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.fullName.isEmpty
                          ? 'Unnamed customer'
                          : customer.fullName,
                      style: const TextStyle(
                        color: _detailInk,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Joined $joined',
                      style: const TextStyle(
                        color: _detailMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Switch(
                    value: !customer.isBlocked,
                    onChanged: customer.uid == appState.profile?.uid
                        ? null
                        : (value) => appState.firestoreService.blockUser(
                              customer.uid,
                              !value,
                            ),
                  ),
                  Text(
                    customer.isBlocked ? 'Blocked' : 'Active',
                    style: TextStyle(
                      color:
                          customer.isBlocked ? _detailDanger : _detailPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: customer.phone),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: customer.hiddenEmail.isEmpty
                ? 'Not provided'
                : customer.hiddenEmail,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Delivery address',
            value: customer.address.isEmpty ? 'Not provided' : customer.address,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.verified_outlined,
            label: 'Phone verified',
            value: customer.isPhoneVerified ? 'Yes' : 'No',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _detailMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _detailMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: _detailInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.totalOrders, required this.totalSpending});

  final int totalOrders;
  final double totalSpending;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(label: 'Total orders', value: '$totalOrders'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Total spending',
            value: _money(totalSpending),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _detailMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _detailInk,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderHistoryTile extends StatelessWidget {
  const _OrderHistoryTile({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final placedAt = DateFormat('dd MMM yyyy, h:mm a').format(order.createdAt);
    final statusColor = _orderStatusColor(order.orderStatus);
    return _DetailCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminOrderDetailsScreen(orderId: order.orderId),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.orderId}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _detailInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  placedAt,
                  style: const TextStyle(
                    color: _detailMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.orderStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _money(order.totalAmount),
                style: const TextStyle(
                  color: _detailInk,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, required this.onDelete});

  final CustomerNote note;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final createdAt =
        DateFormat('dd MMM yyyy, h:mm a').format(note.createdAt);
    return _DetailCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.text,
                  style: const TextStyle(
                    color: _detailInk,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${note.createdByName.isEmpty ? 'Admin' : note.createdByName} '
                  '• $createdAt',
                  style: const TextStyle(
                    color: _detailMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: _detailDanger),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
