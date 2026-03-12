// controllers/coupon_controller.dart
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/coupon_model.dart';
import '../services/coupon_service.dart';
import 'order_controller.dart';

class CouponController extends GetxController {
  final CouponService _couponService = Get.find<CouponService>();

  // Observable variables
  final RxBool isLoading = false.obs;
  final Rx<CouponModel?> selectedCoupon = Rx<CouponModel?>(null);
  final RxList<CouponModel> availableCoupons = <CouponModel>[].obs;

  final RxString couponCode = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;

  final RxBool isCouponApplied = false.obs;
  final RxDouble discountAmount = 0.0.obs;
  final RxDouble subtotal = 0.0.obs;

  // Text editing controller for coupon input
  final TextEditingController couponTextController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
  }

  @override
  void onClose() {
    couponTextController.dispose();
    super.onClose();
  }

  void _setupListeners() {
    couponTextController.addListener(() {
      couponCode.value = couponTextController.text.trim();
      if (errorMessage.value.isNotEmpty) {
        clearMessages();
      }
    });
  }

  // Clear all messages
  void clearMessages() {
    errorMessage.value = '';
    successMessage.value = '';
  }

  // Show error message
  void _showError(String message) {
    errorMessage.value = message;
    successMessage.value = '';
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red.shade600,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  // Show success message
  void _showSuccess(String message) {
    successMessage.value = message;
    errorMessage.value = '';
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green.shade600,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  String _normalizeType(dynamic type) {
    if (type == null) return '';
    String t = type.toString().toLowerCase().trim().replaceAll(' ', '_');
    if (t == 'firsttime') return 'first_time';
    if (t == 'onetime') return 'one_time';
    return t;
  }

  // ✅ MAIN METHOD: Validate coupon and calculate discount locally
  Future<void> validateAndApplyCoupon(
    String code, {
    String paymentMethod = 'COD',
  }) async {
    if (code.trim().isEmpty) {
      _showError('Please enter a coupon code');
      return;
    }

    // New: Check for spaces within the coupon code
    if (code.trim().contains(' ')) {
      _showError('Coupon code cannot contain spaces');
      return;
    }

    try {
      isLoading.value = true;
      clearMessages();

      // Step 1: Validate coupon with API
      final response = await _couponService.validateCouponCode(
        code.trim(),
        paymentMethod: paymentMethod,
      );

      if (response.success && response.data != null) {
        final coupon = response.data!;

        // Step 2: Check if coupon is currently valid (dates)
        if (!coupon.isValid) {
          if (coupon.isExpired) {
            _showError('This coupon has expired');
            return;
          } else if (coupon.isNotYetActive) {
            _showError('This coupon is not yet active');
            return;
          }
        }

        // Step 2.5: Additional Logic Checks (First Order, One Time, etc.)
        final orderController = Get.find<OrderController>();
        final typeStr = _normalizeType(coupon.type);

        // 0. General/First-Time Coupons: Skip all restrictions (highest priority)
        if (typeStr != 'general' && typeStr != 'first_time') {
          // 1. One-time coupons: Skip if already used (standard one-time usage limit)
          if (coupon.usageLimit == 1 || typeStr == 'onetime' || typeStr == 'one_time') {
            final hasUsed = orderController.orderHistory.any((order) => order.couponId == coupon.id);
            if (hasUsed) {
              _showError('You have already used this coupon');
              return;
            }
          }
        }
        
        // Explicitly check first-order for labeled coupons
        if (typeStr == 'first_time' || coupon.isFirstOrderOnly) {
          if (orderController.orderHistory.isNotEmpty) {
            _showError('This coupon is only for first-time orders');
            return;
          }
        }
        
        // Step 3: Calculate discount locally based on your business logic
        final calculatedDiscount = _calculateDiscountAmount(coupon);

        // Step 4: Apply coupon locally
        selectedCoupon.value = coupon;
        discountAmount.value = calculatedDiscount;
        isCouponApplied.value = true;

        if (calculatedDiscount > 0) {
          _showSuccess(
            'Coupon applied! You saved ₹${calculatedDiscount.toStringAsFixed(2)}',
          );
        } else {
          // If discount is 0, still show a basic success message
          // so the user knows the application was successful
          _showSuccess('Coupon Applied Successfully!');
          successMessage.value = ''; 
          errorMessage.value = '';
        }
      } else {
        _showError(response.message ?? 'Invalid coupon');
        resetCouponState(); // Reset state if coupon is invalid
      }
    } on CouponServiceException catch (e) {
      _showError(e.message);
      resetCouponState();
    } catch (e) {
      _showError('Error: $e');
      resetCouponState();
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ LOCAL CALCULATION: Calculate discount based on your business rules
  // ✅ UPDATED: Calculate discount based on MINIMUM of percentage vs value
  double _calculateDiscountAmount(CouponModel coupon) {
    if (subtotal.value <= 0) return 0.0;

    final typeCheck = _normalizeType(coupon.type);
    
    // Allow zero value if it's a percentage coupon OR a special type
    if (coupon.discountValue <= 0 && 
        coupon.discountPercent <= 0 && 
        typeCheck != 'general' && 
        typeCheck != 'first_time' && 
        typeCheck != 'online' && 
        typeCheck != 'prepaid') {
      return 0.0;
    }

    double percentageDiscount = 0.0;
    double valueDiscount = coupon.discountValue;

    // Step 1: Calculate percentage discount on subtotal
    if (coupon.discountPercent > 0) {
      percentageDiscount = (subtotal.value * coupon.discountPercent) / 100;
      
      // Strict Cap Logic (User Requirement): 
      // The 'discountValue' is the absolute maximum discount allowed.
      // If it is 0, the discount IS 0.
      double finalDiscount = percentageDiscount < valueDiscount
          ? percentageDiscount
          : valueDiscount;

      // Ensure discount doesn't exceed subtotal
      if (finalDiscount > subtotal.value) {
        finalDiscount = subtotal.value;
      }
      return double.parse(finalDiscount.toStringAsFixed(2));
    } else {
      // Step 2: Value discount only (no percentage)
      double finalDiscount = valueDiscount;
      
      // Ensure discount doesn't exceed subtotal
      if (finalDiscount > subtotal.value) {
        finalDiscount = subtotal.value;
      }
      return double.parse(finalDiscount.toStringAsFixed(2));
    }
  }

  // Set subtotal for discount calculation
  void setSubtotal(double amount) {
    subtotal.value = amount;

    // Recalculate discount if coupon is applied
    if (isCouponApplied.value && selectedCoupon.value != null) {
      final newDiscount = _calculateDiscountAmount(selectedCoupon.value!);
      discountAmount.value = newDiscount;
      
      // ✅ Update success message with fresh discount value if > 0
      if (newDiscount > 0) {
        successMessage.value = 'Coupon applied! You saved ₹${newDiscount.toStringAsFixed(2)}';
      } else {
        successMessage.value = '';
      }
    }
  }

  // Remove applied coupon
  void removeCoupon() {
    resetCouponState();
    // _showSuccess('Coupon removed');
  }

  // Reset coupon state
  void resetCouponState() {
    selectedCoupon.value = null;
    isCouponApplied.value = false;
    discountAmount.value = 0.0;
    couponTextController.clear();
    couponCode.value = '';
    clearMessages();
  }

  // Clear everything (used when leaving checkout or after successful order)
  void reset() {
    resetCouponState();
    availableCoupons.clear();
  }

  // Get final total after discount
  double getFinalTotal(double deliveryCharge) {
    final subtotalWithDelivery = subtotal.value + deliveryCharge;
    if (!isCouponApplied.value) return subtotalWithDelivery;
    return subtotalWithDelivery - discountAmount.value;
  }

  // ✅ UPDATED: Fetch available coupons with advanced filtering
  Future<void> fetchAvailableCoupons({
    bool refresh = false,
    bool isOnlinePayment = false,
    bool isFirstOrder = false,
  }) async {
    try {
      if (refresh || availableCoupons.isEmpty) {
        isLoading.value = true;
      }

      final response = await _couponService.getAllCoupons(page: 1, limit: 100);

      if (response.success) {
        // Step 1: Filter valid (not expired) and visible coupons
        var filteredList = response.data
            .where((coupon) => coupon.isValid && coupon.isVisible)
            .toList();

        // Step 2: Apply User Logic Filters
        filteredList = filteredList.where((coupon) {
          final typeStr = _normalizeType(coupon.type);

          // 0. General Coupons: ALWAYS visible (highest priority)
          if (typeStr == 'general') {
            return true;
          }

          // 1. One-time coupons: NEVER shown in the app
          if (coupon.usageLimit == 1 || typeStr == 'onetime' || typeStr == 'one_time') {
            return false;
          }

          // 2. First-time coupons: Only show to users with zero orders
          if (typeStr == 'first_time' || coupon.isFirstOrderOnly) {
            final orderController = Get.find<OrderController>();
            // LOGGING: Crucial to see why it's hidden
            print('Coupon Visibility: Checking ${coupon.code}. Order History Length: ${orderController.orderHistory.length}');
            if (orderController.orderHistory.isNotEmpty) {
              return false; 
            }
          }

          // 3. Online/Prepaid coupons: Only for online payment
          final bool isPrepaidCoupon = 
              typeStr == 'online' ||
              typeStr == 'prepaid' ||
              coupon.restrictionPaymentMethod?.toLowerCase() == 'online' ||
              coupon.code.toUpperCase().contains('PREPAID');
          
          if (isPrepaidCoupon && !isOnlinePayment) {
            return false;
          }

          // 4. Zero-Discount Filter: Hide others if they offer no discount
          // Allowed for 'general', 'first_time', and 'prepaid'
          if (_calculateDiscountAmount(coupon) <= 0 && 
              typeStr != 'general' && 
              typeStr != 'first_time' && 
              !isPrepaidCoupon) {
            return false;
          }

          return true;
        }).toList();

        availableCoupons.value = filteredList;
      }
    } catch (e) {
      print('Error fetching available coupons: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Select coupon from available list
  void selectCoupon(CouponModel coupon, {String paymentMethod = 'COD'}) {
    couponTextController.text = coupon.code;
    validateAndApplyCoupon(coupon.code, paymentMethod: paymentMethod);
  }

  // Get order data for placing order (includes coupon info)
  Map<String, dynamic> getOrderCouponData() {
    if (!isCouponApplied.value || selectedCoupon.value == null) {
      return {};
    }

    return {
      'coupon': selectedCoupon.value!.id,
      'couponCode': selectedCoupon.value!.code,
      'discountAmount': discountAmount.value,
      'discountType': selectedCoupon.value!.discountPercent > 0
          ? 'percentage'
          : 'fixed',
    };
  }
}
