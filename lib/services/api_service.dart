import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/branch.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000';
  static const Duration timeoutDuration = Duration(seconds: 30);

  static Future<dynamic> _makeRequest(
    String method,
    String endpoint, {
    dynamic body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      late http.Response response;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(timeoutDuration, onTimeout: () {
            throw Exception('Request timeout after ${timeoutDuration.inSeconds}s');
          });
          break;
        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: jsonEncode(body),
              )
              .timeout(timeoutDuration, onTimeout: () {
            throw Exception('Request timeout after ${timeoutDuration.inSeconds}s');
          });
          break;
        case 'PUT':
          response = await http
              .put(
                uri,
                headers: headers,
                body: jsonEncode(body),
              )
              .timeout(timeoutDuration, onTimeout: () {
            throw Exception('Request timeout after ${timeoutDuration.inSeconds}s');
          });
          break;
        case 'DELETE':
          response = await http
              .delete(
                uri,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(timeoutDuration, onTimeout: () {
            throw Exception('Request timeout after ${timeoutDuration.inSeconds}s');
          });
          break;
        default:
          throw Exception('Invalid HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'];
        } else {
          throw Exception(
            jsonResponse['message'] ?? 'Request failed',
          );
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
          jsonResponse['message'] ?? 'Request failed with status ${response.statusCode}',
        );
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}. Please check your connection.');
    } on Exception catch (e) {
      if (e.toString().contains('Connection refused')) {
        throw Exception('Cannot connect to server. Ensure backend is running on $baseUrl');
      }
      rethrow;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Branch endpoints
  static Future<List<Branch>> getBranches() async {
    final data = await _makeRequest('GET', '/branches');
    return (data as List)
        .map((item) => Branch.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Menu endpoints
  static Future<List<MenuItem>> getMenu() async {
    final data = await _makeRequest('GET', '/menu');
    return (data as List)
        .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<MenuItem>> getMenuByBranch(String branchId) async {
    final data = await _makeRequest('GET', '/menu/$branchId');
    return (data as List)
        .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Cart endpoints
  static Future<List<CartItem>> getCart(String sessionId) async {
    final data = await _makeRequest('GET', '/cart?sessionId=$sessionId');
    return (data as List)
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CartItem>> addToCart({
    required String sessionId,
    required String menuItemId,
    required String branchId,
    required int quantity,
    required List<ExtraOption> selectedExtras,
  }) async {
    final data = await _makeRequest(
      'POST',
      '/cart',
      body: {
        'sessionId': sessionId,
        'menuItemId': menuItemId,
        'branchId': branchId,
        'quantity': quantity,
        'selectedExtras': selectedExtras.map((e) => e.toJson()).toList(),
      },
    );
    return (data as List)
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CartItem>> updateCartItem({
    required String sessionId,
    required String cartItemId,
    required int quantity,
  }) async {
    final data = await _makeRequest(
      'PUT',
      '/cart/$cartItemId',
      body: {
        'sessionId': sessionId,
        'quantity': quantity,
      },
    );
    return (data as List)
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CartItem>> removeFromCart({
    required String sessionId,
    required String cartItemId,
  }) async {
    final data = await _makeRequest(
      'DELETE',
      '/cart/$cartItemId',
      body: {
        'sessionId': sessionId,
      },
    );
    return (data as List)
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<CartItem>> clearCart(String sessionId) async {
    final data = await _makeRequest(
      'DELETE',
      '/cart',
      body: {'sessionId': sessionId},
    );
    return (data as List)
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Order endpoints
  static Future<Order> createOrder({
    required String sessionId,
    required String customerName,
    required String phone,
    required String address,
    required Branch branch,
    String? paymentMethod,
    String? notes,
  }) async {
    final data = await _makeRequest(
      'POST',
      '/orders',
      body: {
        'sessionId': sessionId,
        'customerName': customerName,
        'phone': phone,
        'address': address,
        'branch': branch.toJson(),
        'paymentMethod': paymentMethod ?? 'cash',
        'notes': notes ?? '',
      },
    );
    return Order.fromJson(data as Map<String, dynamic>);
  }

  static Future<Order> getOrder(String orderId) async {
    final data = await _makeRequest('GET', '/orders/$orderId');
    return Order.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<Order>> getAllOrders() async {
    final data = await _makeRequest('GET', '/orders');
    return (data as List)
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Admin login API call
  static Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    try {
      final uri = Uri.parse('$baseUrl/admin/login');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(timeoutDuration);

      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (jsonResponse['success'] == true) {
          return jsonResponse as Map<String, dynamic>;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Login failed');
        }
      } else {
        throw Exception(jsonResponse['message'] ?? 'Login failed with status ${response.statusCode}');
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Fetch all orders for the admin panel
  static Future<List<Order>> getOrders() async {
    final data = await _makeRequest('GET', '/orders');
    return (data as List)
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Update status of a single order
  static Future<Order> updateOrderStatus(String orderId, String status) async {
    final data = await _makeRequest(
      'PUT',
      '/orders/$orderId/status',
      body: {'status': status},
    );
    return Order.fromJson(data as Map<String, dynamic>);
  }
}
