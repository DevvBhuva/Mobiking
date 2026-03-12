
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/services/coupon_service.dart';
import 'package:mobiking/app/data/coupon_model.dart';

void main() async {
  // Mocking what's needed for testing
  Get.put(CouponService());
  final service = Get.find<CouponService>();
  
  print('Fetching coupons...');
  final response = await service.getAllCoupons(page: 1, limit: 100);
  
  if (response.success) {
    print('Found ${response.data.length} coupons total.');
    for (var coupon in response.data) {
      print('---');
      print('Code: ${coupon.code}');
      print('Valid: ${coupon.isValid}');
      print('Visible: ${coupon.isVisible}');
      print('Type: ${coupon.type}');
      print('Usage Limit: ${coupon.usageLimit}');
      print('Payment Restr: ${coupon.restrictionPaymentMethod}');
      print('Is First Order Only: ${coupon.isFirstOrderOnly}');
    }
  } else {
    print('Failed to fetch coupons: ${response.message}');
  }
}
