import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) {
  return Connectivity().onConnectivityChanged;
});

final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityStreamProvider).asData?.value;
  if (connectivity == null || connectivity.isEmpty) {
    return true;
  }
  return !connectivity.contains(ConnectivityResult.none);
});
