// services/coupon_service.dart
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get_storage/get_storage.dart';
import '../data/coupon_model.dart';

class CouponServiceException implements Exception {
  final String message;
  final int? statusCode;

  CouponServiceException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'CouponServiceException: [Status $statusCode] $message';
    }
    return 'CouponServiceException: $message';
  }
}

class CouponService extends GetxService {
  final dio.Dio _dio;
  final GetStorage box;

  CouponService(this._dio, this.box);

  final String _baseUrl = 'https://boxbudy.com/api/v1';

  void _log(String message) {
    print('[CouponService] $message');
  }

  // Get authorization headers with access token
  Map<String, String> _getAuthHeaders() {
    final accessToken = box.read('accessToken');
    if (accessToken == null) {
      throw CouponServiceException(
        'Access token not found. Please log in again.',
      );
    }

    return {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
  }

  // ✅ VALIDATION ONLY: Fetch and validate coupon by code
  Future<CouponResponse> validateCouponCode(
    String couponCode, {
    String paymentMethod = 'COD',
  }) async {
    if (couponCode.trim().isEmpty) {
      throw CouponServiceException('Coupon code cannot be empty.');
    }

    try {
      _log(
        '📤 Validating coupon: $couponCode with payment method: $paymentMethod',
      );

      final encodedCode = Uri.encodeComponent(couponCode);
      final encodedMethod = Uri.encodeComponent(paymentMethod);
      final endpoint = '$_baseUrl/coupon/code/validate/$encodedCode/$encodedMethod';
      _log('🔗 Trying endpoint: $endpoint');

      final response = await _dio.get(
        endpoint,
        options: dio.Options(
          headers: _getAuthHeaders(),
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      _log('✅ Endpoint worked: $endpoint');

      _log(
        '==================== COUPON VALIDATION RESPONSE ====================',
      );
      _log('Status Code: ${response.statusCode}');
      _log('Response Data: ${response.data}');
      _log('=================================================================');

      if (response.statusCode == 200) {
        // Handle different response formats
        if (response.data is Map && response.data['success'] == true) {
          _log('✅ Coupon validated successfully');
          return CouponResponse.fromJson(response.data);
        } else if (response.data is Map && response.data.containsKey('_id')) {
          // Direct coupon data without wrapper
          _log('✅ Direct coupon data received');
          final wrappedResponse = {
            'statusCode': 200,
            'data': response.data,
            'message': 'Coupon validated successfully',
            'success': true,
          };
          return CouponResponse.fromJson(wrappedResponse);
        }
      }

      throw CouponServiceException('Invalid coupon code or coupon not found.');
    } on dio.DioException catch (e) {
      if (e.response != null) {
        final errorMessage =
            e.response?.data?['message'] ?? 'Server error occurred.';
        _log('🔴 Validation error: ${e.response?.statusCode} - $errorMessage');

        if (e.response?.statusCode == 404) {
          throw CouponServiceException('Coupon code not found.');
        } else if (e.response?.statusCode == 401) {
          throw CouponServiceException(
            'Authentication failed. Please log in again.',
          );
        }

        throw CouponServiceException(errorMessage);
      } else {
        throw CouponServiceException('Network error: ${e.message}');
      }
    } catch (e) {
      _log('💥 Unexpected validation error: $e');
      throw CouponServiceException('Coupon validation failed: $e');
    }
  }

  // Optional: Get all available coupons for display
  Future<CouponListResponse> getAllCoupons({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      _log('📤 Fetching available coupons');

      final response = await _dio.get(
        '$_baseUrl/coupon',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'status': 'active',
        },
        options: dio.Options(
          headers: _getAuthHeaders(),
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map && response.data['success'] == true) {
          return CouponListResponse.fromJson(response.data);
        } else if (response.data is List) {
          final wrappedResponse = {
            'statusCode': 200,
            'data': response.data,
            'message': 'Coupons fetched successfully',
            'success': true,
          };
          return CouponListResponse.fromJson(wrappedResponse);
        }
      }

      throw CouponServiceException('Failed to fetch available coupons.');
    } catch (e) {
      _log('Error fetching coupons: $e');
      throw CouponServiceException('Failed to fetch coupons: $e');
    }
  }
}
