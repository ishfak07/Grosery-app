import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _offlineRetryTimer;
  void Function(bool isOnline)? _onStatusChanged;
  var _isOnline = true;
  var _probeGeneration = 0;

  bool get isOnline => _isOnline;

  Future<void> start({
    required void Function(bool isOnline) onStatusChanged,
  }) async {
    _onStatusChanged = onStatusChanged;
    _subscription ??= _connectivity.onConnectivityChanged.listen(
      (results) => unawaited(_handleConnectivityResults(results)),
      onError: (_) => _setOnline(true),
    );

    try {
      final results = await _connectivity.checkConnectivity();
      await _handleConnectivityResults(results);
    } catch (_) {
      _setOnline(true);
    }
  }

  Future<bool> verifyNow() async {
    try {
      final results = await _connectivity.checkConnectivity().timeout(
            const Duration(seconds: 2),
          );
      if (_hasNoNetwork(results)) {
        _setOnline(false);
        _scheduleOfflineRetry();
        return false;
      }
      final isOnline = await _hasInternetAccess();
      _setOnline(isOnline);
      if (!isOnline) {
        _scheduleOfflineRetry();
      }
      return isOnline;
    } catch (_) {
      return _isOnline;
    }
  }

  Future<void> _handleConnectivityResults(
    List<ConnectivityResult> results,
  ) async {
    if (_hasNoNetwork(results)) {
      _setOnline(false);
      _scheduleOfflineRetry();
      return;
    }

    final probeId = ++_probeGeneration;
    final isOnline = await _hasInternetAccess();
    if (probeId != _probeGeneration) {
      return;
    }
    _setOnline(isOnline);
    if (!isOnline) {
      _scheduleOfflineRetry();
    }
  }

  bool _hasNoNetwork(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.none);
  }

  Future<bool> _hasInternetAccess() async {
    final results = await Future.wait([
      _canResolve('firebase.googleapis.com'),
      _canResolve('google.com'),
    ]);
    return results.any((result) => result);
  }

  Future<bool> _canResolve(String host) async {
    try {
      final addresses = await InternetAddress.lookup(host).timeout(
        const Duration(seconds: 3),
      );
      return addresses.any((address) => address.rawAddress.isNotEmpty);
    } catch (_) {
      return false;
    }
  }

  void _setOnline(bool isOnline) {
    if (_isOnline == isOnline) {
      return;
    }
    _isOnline = isOnline;
    _onStatusChanged?.call(isOnline);
    if (isOnline) {
      _offlineRetryTimer?.cancel();
      _offlineRetryTimer = null;
    }
  }

  void _scheduleOfflineRetry() {
    _offlineRetryTimer ??= Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(verifyNow()),
    );
  }

  Future<void> dispose() async {
    _offlineRetryTimer?.cancel();
    await _subscription?.cancel();
  }
}
