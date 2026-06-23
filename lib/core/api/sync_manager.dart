import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_service.dart';

class SyncManager {
  static final SyncManager instance = SyncManager._();
  SyncManager._();

  final _sync = SyncService.instance;
  final _connectivity = Connectivity();
  StreamSubscription? _sub;
  bool _connected = false;

  void init() {
    _connectivity.onConnectivityChanged.listen(_onChange);
    _checkAndSync();
  }

  void _onChange(List<ConnectivityResult> results) {
    final now = results.any((r) => r != ConnectivityResult.none);
    final was = _connected;
    _connected = now;
    if (now && !was) _checkAndSync();
  }

  Future<void> _checkAndSync() async {
    if (!await _sync.isEnabled) return;
    _sync.syncAll();
  }

  Future<void> onPaymentCompleted() async {
    if (!await _sync.isEnabled) return;
    _sync.syncAll();
  }

  void dispose() {
    _sub?.cancel();
  }
}
