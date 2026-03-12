import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/CompanyDetail_model.dart';
import '../../services/policy_service.dart';
import '../../themes/app_theme.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  late Future<CompanyDetails> _companyDetailsFuture;

  @override
  void initState() {
    super.initState();
    _companyDetailsFuture = PolicyService().getCompanyDetails();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make phone call')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email');
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri uri = Uri.parse('https://wa.me/$cleanNumber');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Contact Us',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        centerTitle: false,
      ),
      body: FutureBuilder<CompanyDetails>(
        future: _companyDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading contact info'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No contact info available'));
          }

          final details = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  title: 'Contact Information',
                  icon: Icons.contact_phone_outlined,
                  children: [
                    _buildContactItem(
                      icon: Icons.location_on_outlined,
                      title: 'Address',
                      value: details.address,
                      onTap: null,
                    ),
                    _buildContactItem(
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      value: details.phoneNo,
                      onTap: () => _makePhoneCall(details.phoneNo),
                    ),
                    _buildContactItem(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: details.email,
                      onTap: () => _sendEmail(details.email),
                    ),
                    if (details.whatsappNo.isNotEmpty)
                      _buildContactItem(
                        icon: Icons.chat_outlined,
                        title: 'WhatsApp',
                        value: details.whatsappNo,
                        onTap: () => _openWhatsApp(details.whatsappNo),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Follow Us',
                  icon: Icons.share_outlined,
                  children: [_buildSocialMediaGrid(details)],
                ),
              ],
            ),
          );
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
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primaryPurple),
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

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: AppColors.primaryPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialMediaGrid(CompanyDetails details) {
    final socialMedia = [
      if (details.instaLink.isNotEmpty)
        {
          'isImage': true,
          'image':
              'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Instagram_logo_2016.svg/132px-Instagram_logo_2016.svg.png',
          'label': 'Instagram',
          'url': details.instaLink,
          'color': const Color(0xFFE4405F),
        },
      if (details.facebookLink != null)
        {
          'icon': Icons.facebook,
          'label': 'Facebook',
          'url': details.facebookLink!,
          'color': const Color(0xFF1877F2),
        },
      if (details.twitterLink != null)
        {
          'icon': Icons.flutter_dash,
          'label': 'Twitter',
          'url': details.twitterLink!,
          'color': const Color(0xFF1DA1F2),
        },
      if (details.websiteLink != null)
        {
          'icon': Icons.language,
          'label': 'Website',
          'url': details.websiteLink!,
          'color': Colors.grey.shade700,
        },
    ];

    if (socialMedia.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: socialMedia.map((social) {
        return InkWell(
          onTap: () => _launchUrl(social['url'] as String),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: (MediaQuery.of(context).size.width - 80) / 2,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: (social['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (social['color'] as Color).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (social['isImage'] == true)
                  Image.network(
                    social['image'] as String,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  )
                else
                  Icon(
                    social['icon'] as IconData,
                    color: social['color'] as Color,
                    size: 24,
                  ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    social['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: social['color'] as Color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
