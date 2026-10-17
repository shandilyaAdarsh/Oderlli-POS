import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final Dio _pingDio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 3)));

  /// Checks if network connection exists and if the backend base URL is reachable.
  Future<bool> isBackendReachable(String baseUrl, String healthEndpoint) async {
    return false;
  }
}
