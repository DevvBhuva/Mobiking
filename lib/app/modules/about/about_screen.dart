import 'package:flutter/material.dart';
import 'package:mobiking/app/data/CompanyDetail_model.dart';
import 'package:mobiking/app/services/policy_service.dart';
import 'package:mobiking/app/themes/app_theme.dart';
import 'package:flutter_html/flutter_html.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late Future<CompanyDetails> _companyDetailsFuture;

  @override
  void initState() {
    super.initState();
    _companyDetailsFuture = PolicyService().getCompanyDetails();
  }

  void _refreshCompanyDetails() {
    setState(() {
      _companyDetailsFuture = PolicyService().getCompanyDetails();
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: FutureBuilder<CompanyDetails>(
        future: _companyDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryPurple ?? Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading company details...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            print('Error fetching company details: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unable to load company details. Please try again.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _refreshCompanyDetails,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple ?? Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final details = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                _refreshCompanyDetails();
                await _companyDetailsFuture;
              },
              color: AppColors.primaryPurple ?? Colors.blue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Logo (if available)
                    if (details.logoImage != null)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              details.logoImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.business,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    // Dynamic HTML Content or Fallback Static Sections
                    if (details.about != null && details.about!.trim().isNotEmpty)
                      Html(
                        data: details.about!,
                        style: {
                          "h2": Style(
                            fontSize: FontSize(18),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            margin: Margins.only(top: 24, bottom: 8),
                          ),
                          "p": Style(
                            fontSize: FontSize(14),
                            lineHeight: LineHeight(1.5),
                            color: Colors.grey.shade800,
                            margin: Margins.only(bottom: 12),
                          ),
                          "ul": Style(
                            padding: HtmlPaddings.only(left: 16),
                            margin: Margins.only(bottom: 16),
                          ),
                          "li": Style(
                            fontSize: FontSize(14),
                            margin: Margins.only(bottom: 8),
                            color: Colors.grey.shade800,
                          ),
                          ".section-card": Style(
                            backgroundColor: Colors.white,
                            padding: HtmlPaddings.all(16),
                            margin: Margins.only(bottom: 16),
                          ),
                        },
                      )
                    else ...[
                      // About Mobiking Section
                    _buildSectionCard(
                      title: 'About Mobiking',
                      icon: Icons.info_outline_rounded,
                      children: [
                        Text(
                          'Welcome to Mobiking, a platform created for customers who love to purchase premium gadgets but prefer to buy them at smart and affordable prices.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'In today’s market, many people wish to own branded electronics such as earbuds, smartwatches, power banks, chargers, gaming accessories, and other mobile gadgets from well-known brands like Apple, Sony, OnePlus, and Realme. However, the high retail price of these premium products often makes customers hesitate before making a purchase.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Mobiking was built with a simple idea — why pay full price when you can enjoy the same branded product at a much better value? This is where the open-box category becomes a smart and practical choice.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Mobiking specializes in offering carefully verified open-box electronics, which are genuine branded products that may have been previously opened for several legitimate reasons. These may include bulk inventory purchased directly from brands or distributors, packaging damage during shipping, showroom display units, customer returns, or excess inventory from retailers.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Our team carefully inspects, tests, and verifies each product through a detailed quality check process before making it available for sale again. Only products that meet our functional standards are approved for listing on our platform.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This process allows customers to purchase premium branded gadgets at significantly lower prices compared to traditional retail stores or even many wholesale markets.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Our goal is simple and clear:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint('Provide genuine branded gadgets'),
                        _buildBulletPoint(
                          'Maintain transparency about product condition',
                        ),
                        _buildBulletPoint('Offer affordable prices for smart buyers'),
                        _buildBulletPoint(
                          'Build long-term customer trust through honest service',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'At Mobiking, we believe that technology should be accessible without unnecessary high costs. By offering verified open-box products, we aim to help customers enjoy premium gadgets while making a smarter and more economical buying decision.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Our Vision Section
                    _buildSectionCard(
                      title: 'Our Vision',
                      icon: Icons.visibility_outlined,
                      children: [
                        Text(
                          'Our vision is to build a reliable and transparent platform where customers can confidently purchase quality electronics at reasonable prices.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We aim to become a trusted destination for people who want to enjoy premium gadgets without overspending. By promoting open-box products, we also support a more sustainable approach to technology consumption, where perfectly usable devices are reused rather than wasted.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'In a market where gadget prices continue to rise, Mobiking focuses on helping customers make smarter buying decisions.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Our Mission Section
                    _buildSectionCard(
                      title: 'Our Mission',
                      icon: Icons.track_changes_rounded,
                      children: [
                        Text(
                          'Our mission at Mobiking is to create a shopping experience where customers can confidently purchase premium electronics at affordable prices, without worrying about quality or authenticity.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We aim to bridge the gap between high-end branded gadgets and budget-conscious buyers by offering carefully verified open-box products that deliver excellent value for money.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'At Mobiking, we continuously work on improving our platform, including regularly upgrading our website and app interface (UI) to make browsing, comparing, and purchasing products simple and convenient for our customers.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Along with this, we actively monitor market trends and customer demand so that we can gradually expand our product range and introduce new electronic categories that customers are looking for. Our goal is to ensure that Mobiking remains a reliable destination for trending gadgets and essential tech accessories.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Through our efforts, we strive to ensure that every customer receives:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint(
                          'Genuine branded electronics from trusted manufacturers',
                        ),
                        _buildBulletPoint(
                          'Properly tested and quality-verified gadgets',
                        ),
                        _buildBulletPoint('Honest and transparent product information'),
                        _buildBulletPoint(
                          'Fair and affordable pricing that delivers real value',
                        ),
                        _buildBulletPoint(
                          'A growing range of popular electronics and accessories based on market trends',
                        ),
                        _buildBulletPoint(
                          'Helpful customer assistance whenever support is required',
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'By consistently focusing on these commitments, Mobiking aims to build a platform where customers feel confident, comfortable, and satisfied with every purchase they make.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Our mission is not only to sell gadgets, but also to create a marketplace where customers feel they are getting the right product, at the right price, with the right level of trust.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),

                    // Why Customers Prefer Mobiking Section
                    _buildSectionCard(
                      title: 'Why Customers Prefer Mobiking',
                      icon: Icons.thumb_up_alt_outlined,
                      children: [
                        Text(
                          'When customers shop for electronics online, they often look for three important things — trust, value for money, and product reliability. At Mobiking, we focus on these priorities so that customers can feel confident while making their purchase decisions.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unlike many marketplaces that only focus on selling products, Mobiking is designed to provide a balanced combination of affordability and transparency, helping customers enjoy premium gadgets without paying unnecessarily high prices.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'One of the main reasons customers choose Mobiking is the significant price advantage. Many of the products available on our platform come from open-box inventory, bulk brand purchases, retail excess stock, or display units. Because of this sourcing model, we are able to offer well-known branded gadgets at prices that are often much lower than traditional retail stores.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Another important factor is our product verification process. Before any product is listed on our platform, it goes through a careful inspection and functional testing process by our team. This helps ensure that customers receive gadgets that are properly working and ready to use, even though they may be sold under the open-box category.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Mobiking also focuses on offering popular and trending gadget categories such as earbuds, smartwatches, neckbands, power banks, chargers, and gaming accessories. As technology trends continue to evolve, we regularly explore new categories so that customers can find the gadgets they are looking for in one place.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Some of the key reasons customers prefer Mobiking include:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint(
                          'Access to genuine branded electronics at more affordable prices',
                        ),
                        _buildBulletPoint(
                          'Verified open-box products that go through a quality checking process',
                        ),
                        _buildBulletPoint(
                          'A wide range of popular and trending gadget categories',
                        ),
                        _buildBulletPoint(
                          'Limited stock deals that provide excellent value for smart buyers',
                        ),
                        _buildBulletPoint(
                          'Secure payment options and convenient ordering process',
                        ),
                        _buildBulletPoint(
                          'Responsive customer support whenever assistance is required',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'For many customers, Mobiking has become a smart alternative to paying full retail prices, especially when the same gadget can be purchased at a better value without compromising functionality.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Our goal is to make sure that every customer who shops with Mobiking feels that they have made a practical, informed, and worthwhile purchase. At the end of the day, Mobiking is built for people who believe that buying smart is always better than simply buying expensive.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    ], // End of Fallback Static Content

                    const SizedBox(height: 16),

                  ],
                ),
              ),
            );
          } else {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No company details found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (AppColors.primaryPurple ?? Colors.blue).withOpacity(
                      0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: AppColors.primaryPurple ?? Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
