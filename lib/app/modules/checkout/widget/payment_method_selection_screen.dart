// lib/app/modules/checkout/views/payment_method_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import '../../../controllers/order_controller.dart';

class PaymentMethodSelectionScreen extends StatefulWidget {
  final String? initialMethod;

  const PaymentMethodSelectionScreen({Key? key, this.initialMethod}) : super(key: key);

  @override
  State<PaymentMethodSelectionScreen> createState() => _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState extends State<PaymentMethodSelectionScreen> {
  final OrderController orderController = Get.find<OrderController>();
  late String selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    selectedPaymentMethod = widget.initialMethod ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.neutralBackground,
      appBar: AppBar(
        title: Text(
          "Select Payment Method",
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildPaymentOption(
                context: context,
                title: "Cash on Delivery (COD)",
                description: "Pay with cash upon delivery.",
                icon: Icons.money_rounded,
                onTap: () {
                        setState(() {
                          selectedPaymentMethod = 'COD';
                        });
                      },
                isSelected: selectedPaymentMethod == 'COD',
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                context: context,
                title: "Online Payment",
                description: "Pay securely online with cards or UPI.",
                icon: Icons.payment_rounded,
                onTap: () {
                        setState(() {
                          selectedPaymentMethod = 'online';
                        });
                      },
                isSelected: selectedPaymentMethod == 'online',
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger.withOpacity(0.1),
                        foregroundColor: AppColors.danger,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(48),
                        elevation: 0,
                        side: const BorderSide(
                          color: AppColors.danger,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedPaymentMethod.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).pop(selectedPaymentMethod);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(48),
                        elevation: 4,
                        disabledBackgroundColor: AppColors.lightPurple
                            .withOpacity(0.5),
                      ),
                      child: Text(
                        'Select',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isSelected,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.lightPurple.withOpacity(0.2)
                : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryPurple
                  : AppColors.lightPurple,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              BoxShadow(
                color: AppColors.textDark.withOpacity(0.03),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppColors.primaryPurple
                    : AppColors.textMedium,
                size: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primaryPurple
                            : AppColors.textDark,
                      ),
                    ),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 24,
                ),
            ],
          ),
        ),
    );
  }
}
