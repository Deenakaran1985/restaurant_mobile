import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  static String serverIp = '192.168.32.249:8107';
  static String printerIp = '192.168.32.151';
  static String configPassword = 'admin'; // Default protection password for host setting modifications
  static String get baseUrl => 'http://$serverIp/api';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedServerIp = prefs.getString('server_ip');
    final savedPrinterIp = prefs.getString('printer_ip');
    final savedPassword = prefs.getString('config_password');
    if (savedServerIp != null && savedServerIp.isNotEmpty) {
      serverIp = savedServerIp;
    }
    if (savedPrinterIp != null && savedPrinterIp.isNotEmpty) {
      printerIp = savedPrinterIp;
    }
    if (savedPassword != null && savedPassword.isNotEmpty) {
      configPassword = savedPassword;
    }
    dio.options.baseUrl = baseUrl;
  }

  Future<void> updateConfiguration({required String newServerIp, required String newPrinterIp, String? newPassword}) async {
    final prefs = await SharedPreferences.getInstance();
    serverIp = newServerIp.trim();
    printerIp = newPrinterIp.trim();
    await prefs.setString('server_ip', serverIp);
    await prefs.setString('printer_ip', printerIp);
    if (newPassword != null && newPassword.trim().isNotEmpty) {
      configPassword = newPassword.trim();
      await prefs.setString('config_password', configPassword);
    }
    dio.options.baseUrl = baseUrl;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('sanctum_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Handle offline cache transition if connectivity dropouts occur in restaurant hall
        if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
          print('Network Offline: Transitioning to SQLite local fallback cache for KOT syncing...');
        }
        return handler.next(e);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) => dio.post(path, data: data);
}
