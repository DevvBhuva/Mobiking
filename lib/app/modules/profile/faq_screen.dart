import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobiking/app/themes/app_theme.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  final List<Map<String, dynamic>> _faqs = const [
    {
      'question': 'Are the products original?',
      'answer':
          'Yes, all products are 100% genuine branded gadgets, sourced from trusted inventory partners.',
      'category': 'Product',
    },
    {
      'question': 'Why are the prices lower?',
      'answer':
          'Because we purchase directly from authorized brands in large bulk quantities, avoiding extra distributor and wholesaler costs. This helps us offer genuine branded gadgets at more affordable prices for our customers.',
      'category': 'Pricing',
    },
    {
      'question': 'Do you provide Cash on Delivery?',
      'answer':
          'Yes, Cash on Delivery (COD) is available across Pan India, so customers can order with confidence and pay at the time of delivery.',
      'category': 'Payment',
    },
    {
      'question': 'How many days does delivery take?',
      'answer':
          'Delivery usually takes 2–5 working days, depending on your city and local logistics.',
      'category': 'Shipping',
    },
    {
      'question': 'Can I ask questions before ordering?',
      'answer':
          'Yes, our team is happy to help you before purchase. Our support team is available 12:30 PM to 8:30 PM, and remains closed on Tuesdays.',
      'category': 'Support',
    },
    {
      'question': 'Why should I buy from Mobiking?',
      'answer':
          'Because you get genuine branded gadgets at much better prices, carefully checked products, and reliable support—making it a smart and trusted way to buy premium gadgets.',
      'category': 'General',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'Frequently Asked Questions',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            debugPrint('🔙 FAQ: Back button pressed');
            HapticFeedback.mediumImpact();
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Get.back();
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: _faqs.length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.grey.shade100,
          height: 32,
        ),
        itemBuilder: (context, index) {
          return _buildMinimalFAQTile(_faqs[index]);
        },
      ),
    );
  }

  Widget _buildMinimalFAQTile(Map<String, dynamic> faq) {
    return Theme(
      data: ThemeData().copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        iconColor: AppColors.primaryPurple,
        collapsedIconColor: Colors.grey.shade400,
        title: Text(
          faq['question'] as String,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            height: 1.4,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq['answer'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textLight,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (faq['category'] as String).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryPurple,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
