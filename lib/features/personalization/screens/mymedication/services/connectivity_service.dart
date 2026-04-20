import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_service.dart';

/// Service to monitor network connectivity and trigger sync when online
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  static bool _isOnline = false;
  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Get the current online status
  static bool get isOnline => _isOnline;

  /// Stream that emits true when online, false when offline
  static Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Initialize the connectivity service
  static Future<void> initialize() async {
    // Check initial connectivity
    final List<ConnectivityResult> result = await _connectivity
        .checkConnectivity();
    _isOnline = _isConnected(result);

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      final bool wasOnline = _isOnline;
      _isOnline = _isConnected(result);

      // Emit connectivity status
      _connectivityController.add(_isOnline);

      // If we just came online, trigger sync
      if (!wasOnline && _isOnline) {
        print('📡 Connectivity restored - triggering sync...');
        SyncService.trySyncNow();
      } else if (wasOnline && !_isOnline) {
        print('📡 Connectivity lost - offline mode active');
      }
    });
  }

  /// Check if connected based on connectivity result
  static bool _isConnected(List<ConnectivityResult> result) {
    return result.isNotEmpty &&
        result.any(
          (r) =>
              r == ConnectivityResult.mobile ||
              r == ConnectivityResult.wifi ||
              r == ConnectivityResult.ethernet,
        );
  }

  /// Manually check current connectivity
  static Future<bool> checkConnectivity() async {
    final List<ConnectivityResult> result = await _connectivity
        .checkConnectivity();
    _isOnline = _isConnected(result);
    return _isOnline;
  }

  /// Dispose the service
  static Future<void> dispose() async {
    await _subscription?.cancel();
    await _connectivityController.close();
  }
}
