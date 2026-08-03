import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../models/models.dart';
import '../../services/order_cancellation_service.dart';

typedef OrderCancellationCountdownBuilder = Widget Function(
  BuildContext context,
  OrderCancellationSnapshot snapshot,
);

class OrderCancellationCountdown extends StatefulWidget {
  const OrderCancellationCountdown({
    super.key,
    required this.order,
    required this.builder,
    this.now,
  });

  final OrderModel order;
  final OrderCancellationCountdownBuilder builder;
  final DateTime Function()? now;

  @override
  State<OrderCancellationCountdown> createState() =>
      _OrderCancellationCountdownState();
}

class _OrderCancellationCountdownState
    extends State<OrderCancellationCountdown> {
  late OrderCancellationSnapshot _snapshot;
  StreamSubscription<DateTime>? _tickerSubscription;

  @override
  void initState() {
    super.initState();
    _snapshot = _calculateSnapshot();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant OrderCancellationCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSnapshot(setStateForChange: true);
  }

  @override
  void dispose() {
    _tickerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _snapshot);
  }

  OrderCancellationSnapshot _calculateSnapshot([DateTime? now]) {
    return OrderCancellationPolicy.snapshotFor(
      widget.order,
      now: now ?? widget.now?.call() ?? DateTime.now(),
    );
  }

  void _updateSnapshot({required bool setStateForChange, DateTime? now}) {
    final next = _calculateSnapshot(now);
    if (next != _snapshot) {
      if (setStateForChange && mounted) {
        setState(() => _snapshot = next);
      } else {
        _snapshot = next;
      }
    }
    _syncTicker();
  }

  void _syncTicker() {
    if (_snapshot.isActive) {
      _tickerSubscription ??= _OrderCancellationTicker.stream.listen(
        (now) => _updateSnapshot(setStateForChange: true, now: now),
      );
    } else {
      _tickerSubscription?.cancel();
      _tickerSubscription = null;
    }
  }
}

class _OrderCancellationTicker {
  const _OrderCancellationTicker._();

  static Timer? _timer;
  static final _controller = StreamController<DateTime>.broadcast(
    onListen: _start,
    onCancel: _stop,
  );

  static Stream<DateTime> get stream => _controller.stream;

  static void _start() {
    if (_timer != null) {
      return;
    }
    _controller.add(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_controller.isClosed) {
        _controller.add(DateTime.now());
      }
    });
  }

  static void _stop() {
    _timer?.cancel();
    _timer = null;
  }
}
