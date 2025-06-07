import 'package:http/http.dart' as http;
import 'package:alist_flutter/contant/native_bridge.dart';
import 'package:alist_flutter/generated_api.dart';

class ProxyHttpClient {
  static ProxyHttpClient? _instance;
  static ProxyHttpClient get instance => _instance ??= ProxyHttpClient._();

  late http.Client _client;
  
  ProxyHttpClient._() {
    _client = http.Client();
<<<<<<< HEAD
    _updateProxySettings();
  }

  Future<void> _updateProxySettings() async {
=======
    updateProxySettings();
  }

  Future<void> updateProxySettings() async {
>>>>>>> 38f7e93 (http proxy)
    final cfg = AppConfig();
    final isEnabled = await cfg.isProxyEnabled();
    if (isEnabled) {
      final host = await cfg.getProxyHost();
      final port = await cfg.getProxyPort();
      if (host.isNotEmpty && port > 0) {
        // Set system-wide proxy for Dart HTTP client
        final proxy = '$host:$port';
        _client = http.Client();
        // Set the HTTP_PROXY and HTTPS_PROXY environment variables
        Map<String, String> envVars = {
          'HTTP_PROXY': 'http://$proxy',
          'HTTPS_PROXY': 'http://$proxy',
        };
        // Apply environment variables
        envVars.forEach((key, value) {
          if (value.isNotEmpty) {
            _setEnvironmentVariable(key, value);
          }
        });
      }
    }
  }

  void _setEnvironmentVariable(String key, String value) {
    // This is a simplified version. In a real app, you might want to use
    // platform-specific code to set environment variables
    const platform = const bool.hasEnvironment('dart.vm.product')
        ? 'release'
        : 'development';
    print('Setting $platform proxy: $key=$value');
  }

  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    return await _client.get(Uri.parse(url), headers: headers);
  }

  Future<http.Response> post(String url,
      {Map<String, String>? headers, dynamic body}) async {
    return await _client.post(Uri.parse(url), headers: headers, body: body);
  }

  Future<http.Response> put(String url,
      {Map<String, String>? headers, dynamic body}) async {
    return await _client.put(Uri.parse(url), headers: headers, body: body);
  }

  Future<http.Response> delete(String url, {Map<String, String>? headers}) async {
    return await _client.delete(Uri.parse(url), headers: headers);
  }

  void dispose() {
    _client.close();
  }
} 