import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _language = 'English';
  String _currency = 'USD';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildProfileCard(context),
              const SizedBox(height: 24),
              _buildSection('Account', [
                _SettingsItem(icon: Iconsax.user, label: 'Personal Information', onTap: () => _showPersonalInfoSheet(context)),
                _SettingsItem(icon: Iconsax.lock, label: 'Password & Security', onTap: () => _showSecuritySheet(context)),
                _SettingsItem(icon: Iconsax.card, label: 'Payment Methods', onTap: () => _showPaymentMethodsSheet(context)),
                _SettingsItem(icon: Iconsax.wallet_2, label: 'Bank Accounts', onTap: () => _showBankAccountsSheet(context)),
              ]),
              const SizedBox(height: 16),
              _buildSection('Store', [
                _SettingsItem(icon: Iconsax.shop, label: 'Store Profile', onTap: () => _showStoreProfileSheet(context)),
                _SettingsItem(icon: Iconsax.location, label: 'Store Address', onTap: () => _showStoreAddressSheet(context)),
                _SettingsItem(icon: Iconsax.clock, label: 'Business Hours', onTap: () => _showBusinessHoursSheet(context)),
                _SettingsItem(icon: Iconsax.document, label: 'Policies', onTap: () => _showPoliciesSheet(context)),
              ]),
              const SizedBox(height: 16),
              _buildSection('Preferences', [
                _SettingsItem(icon: Iconsax.notification, label: 'Notifications', trailing: _buildSwitch(_notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)), onTap: () {}),
                _SettingsItem(icon: Iconsax.language_square, label: 'Language', trailing: _buildTrailingText(_language), onTap: () => _showLanguageSheet(context)),
                _SettingsItem(icon: Iconsax.dollar_circle, label: 'Currency', trailing: _buildTrailingText(_currency), onTap: () => _showCurrencySheet(context)),
              ]),
              const SizedBox(height: 16),
              _buildSection('Support', [
                _SettingsItem(icon: Iconsax.message_question, label: 'Help Center', onTap: () => _showHelpCenterSheet(context)),
                _SettingsItem(icon: Iconsax.message, label: 'Contact Support', onTap: () => _showContactSupportSheet(context)),
                _SettingsItem(icon: Iconsax.document_text, label: 'Terms of Service', onTap: () => _showTermsSheet(context)),
                _SettingsItem(icon: Iconsax.shield_tick, label: 'Privacy Policy', onTap: () => _showPrivacySheet(context)),
              ]),
              const SizedBox(height: 24),
              _buildLogoutButton(context),
              const SizedBox(height: 16),
              _buildVersionInfo(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
              child: const Icon(Iconsax.arrow_left, color: Colors.black, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Text('Settings', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _showEditProfileSheet(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Iconsax.user, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('John Doe', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                    Text('john@glowcart.com', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                      child: Text('Pro Plan', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(bool value, Function(bool) onChanged) {
    return Switch(value: value, onChanged: onChanged, activeColor: Colors.black, activeTrackColor: Colors.grey[400], inactiveThumbColor: Colors.grey[400], inactiveTrackColor: Colors.grey[200]);
  }

  Widget _buildTrailingText(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(width: 4),
        Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 18),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[300]!)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.logout, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              Text('Log Out', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Column(
        children: [
          Text('GlowCart Store', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600])),
          Text('Version 1.0.0', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.poppins(color: Colors.grey[600])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600]))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/login');
            },
            child: Text('Log Out', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context, String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
                  const Spacer(),
                  GestureDetector(onTap: () => Navigator.pop(ctx), child: Icon(Iconsax.close_circle, color: Colors.grey[400])),
                ],
              ),
            ),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16), child: content)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {bool obscure = false, int maxLines = 1, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSaveButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text('Save Changes', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    _showBottomSheet(context, 'Edit Profile', Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)), child: const Icon(Iconsax.user, color: Colors.white, size: 36)),
              Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle), child: const Icon(Iconsax.camera, size: 16, color: Colors.black))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField('Full Name', 'John Doe'),
        _buildTextField('Email', 'john@glowcart.com'),
        _buildTextField('Phone', '+1 234 567 8900'),
        _buildSaveButton(() => Navigator.pop(context)),
      ],
    ));
  }

  void _showPersonalInfoSheet(BuildContext context) {
    _showBottomSheet(context, 'Personal Information', Column(
      children: [
        _buildTextField('Full Name', 'John Doe'),
        _buildTextField('Email', 'john@glowcart.com'),
        _buildTextField('Phone Number', '+1 234 567 8900'),
        _buildTextField('Date of Birth', 'January 1, 1990'),
        _buildSaveButton(() => Navigator.pop(context)),
      ],
    ));
  }

  void _showSecuritySheet(BuildContext context) {
    _showBottomSheet(context, 'Password & Security', Column(
      children: [
        _buildTextField('Current Password', '••••••••', obscure: true),
        _buildTextField('New Password', 'Enter new password', obscure: true),
        _buildTextField('Confirm Password', 'Confirm new password', obscure: true),
        const SizedBox(height: 16),
        _buildSecurityOption('Two-Factor Authentication', 'Add extra security to your account', true),
        _buildSecurityOption('Login Alerts', 'Get notified of new logins', true),
        const SizedBox(height: 16),
        _buildSaveButton(() => Navigator.pop(context)),
      ],
    ));
  }

  Widget _buildSecurityOption(String title, String subtitle, bool enabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: (_) {}, activeColor: Colors.black),
        ],
      ),
    );
  }

  void _showPaymentMethodsSheet(BuildContext context) {
    _showBottomSheet(context, 'Payment Methods', Column(
      children: [
        _buildPaymentCard('Visa', '•••• 4242', true),
        _buildPaymentCard('Mastercard', '•••• 8888', false),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.add, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('Add Payment Method', style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildPaymentCard(String type, String number, bool isDefault) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Icon(Iconsax.card, color: Colors.black)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
                Text(number, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          if (isDefault) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)), child: Text('Default', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white))),
        ],
      ),
    );
  }

  void _showBankAccountsSheet(BuildContext context) {
    _showBottomSheet(context, 'Bank Accounts', Column(
      children: [
        _buildBankAccount('Chase Bank', '•••• 1234', true),
        _buildBankAccount('Bank of America', '•••• 5678', false),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.add, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('Add Bank Account', style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildBankAccount(String bank, String number, bool isDefault) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Icon(Iconsax.bank, color: Colors.black)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bank, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
                Text(number, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          if (isDefault) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)), child: Text('Primary', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white))),
        ],
      ),
    );
  }

  void _showStoreProfileSheet(BuildContext context) {
    _showBottomSheet(context, 'Store Profile', Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)), child: const Icon(Iconsax.shop, color: Colors.white, size: 36)),
              Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle), child: const Icon(Iconsax.camera, size: 16, color: Colors.black))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField('Store Name', 'My Awesome Store'),
        _buildTextField('Store URL', 'mystore.glowcart.com'),
        _buildTextField('Description', 'Tell customers about your store...', maxLines: 3),
        _buildTextField('Category', 'Fashion & Apparel'),
        _buildSaveButton(() => Navigator.pop(context)),
      ],
    ));
  }

  void _showStoreAddressSheet(BuildContext context) {
    _showBottomSheet(context, 'Store Address', Column(
      children: [
        _buildTextField('Street Address', '123 Main Street'),
        _buildTextField('City', 'New York'),
        _buildTextField('State/Province', 'NY'),
        _buildTextField('Postal Code', '10001'),
        _buildTextField('Country', 'United States'),
        _buildSaveButton(() => Navigator.pop(context)),
      ],
    ));
  }

  void _showBusinessHoursSheet(BuildContext context) {
    _showBottomSheet(context, 'Business Hours', Column(
      children: [
        _buildDayHours('Monday', '9:00 AM', '6:00 PM', true),
        _buildDayHours('Tuesday', '9:00 AM', '6:00 PM', true),
        _buildDayHours('Wednesday', '9:00 AM', '6:00 PM', true),
        _buildDayHours('Thursday', '9:00 AM', '6:00 PM', true),
        _buildDayHours('Friday', '9:00 AM', '6:00 PM', true),
        _buildDayHours('Saturday', '10:00 AM', '4:00 PM', true),
        _buildDayHours('Sunday', 'Closed', 'Closed', false),
        const SizedBox(height: 16),
        _buildSaveButton(() => Navigator.pop(context)),
      ],
    ));
  }

  Widget _buildDayHours(String day, String open, String close, bool isOpen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(day, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black))),
          Expanded(child: Text(isOpen ? '$open - $close' : 'Closed', style: GoogleFonts.poppins(color: isOpen ? Colors.grey[700] : Colors.grey[400]))),
          Switch(value: isOpen, onChanged: (_) {}, activeColor: Colors.black),
        ],
      ),
    );
  }

  void _showPoliciesSheet(BuildContext context) {
    _showBottomSheet(context, 'Store Policies', Column(
      children: [
        _buildPolicyItem('Return Policy', 'Define your return and refund policy'),
        _buildPolicyItem('Shipping Policy', 'Set shipping terms and conditions'),
        _buildPolicyItem('Privacy Policy', 'Customer data handling policy'),
        _buildPolicyItem('Terms of Service', 'Store terms and conditions'),
      ],
    ));
  }

  Widget _buildPolicyItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        trailing: Icon(Iconsax.edit_2, color: Colors.grey[400], size: 20),
        onTap: () {},
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final languages = ['English', 'Spanish', 'French', 'German', 'Chinese', 'Japanese', 'Arabic'];
    _showBottomSheet(context, 'Language', Column(
      children: languages.map((lang) => _buildSelectionItem(lang, _language == lang, () {
        setState(() => _language = lang);
        Navigator.pop(context);
      })).toList(),
    ));
  }

  void _showCurrencySheet(BuildContext context) {
    final currencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY', 'CNY'];
    _showBottomSheet(context, 'Currency', Column(
      children: currencies.map((curr) => _buildSelectionItem(curr, _currency == curr, () {
        setState(() => _currency = curr);
        Navigator.pop(context);
      })).toList(),
    ));
  }

  Widget _buildSelectionItem(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isSelected ? Colors.black : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.black)),
            const Spacer(),
            if (isSelected) const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  void _showHelpCenterSheet(BuildContext context) {
    _showBottomSheet(context, 'Help Center', Column(
      children: [
        _buildHelpItem(Iconsax.book_1, 'Getting Started', 'Learn the basics of selling'),
        _buildHelpItem(Iconsax.box, 'Managing Products', 'Add and edit your products'),
        _buildHelpItem(Iconsax.receipt_2, 'Orders & Fulfillment', 'Process and ship orders'),
        _buildHelpItem(Iconsax.wallet_2, 'Payments & Payouts', 'Understand your earnings'),
        _buildHelpItem(Iconsax.chart_2, 'Analytics & Reports', 'Track your performance'),
        _buildHelpItem(Iconsax.truck_fast, 'Shipping Setup', 'Configure shipping options'),
      ],
    ));
  }

  Widget _buildHelpItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.black, size: 20)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        trailing: Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 18),
        onTap: () {},
      ),
    );
  }

  void _showContactSupportSheet(BuildContext context) {
    _showBottomSheet(context, 'Contact Support', Column(
      children: [
        _buildContactOption(Iconsax.message, 'Live Chat', 'Chat with our support team', () {}),
        _buildContactOption(Iconsax.sms, 'Email Support', 'support@glowcart.com', () {}),
        _buildContactOption(Iconsax.call, 'Phone Support', '+1 800 123 4567', () {}),
        const SizedBox(height: 24),
        Text('Support Hours', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Text('Monday - Friday: 9AM - 6PM EST\nSaturday: 10AM - 4PM EST\nSunday: Closed', style: GoogleFonts.poppins(color: Colors.grey[600], height: 1.5), textAlign: TextAlign.center),
      ],
    ));
  }

  Widget _buildContactOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  void _showTermsSheet(BuildContext context) {
    _showBottomSheet(context, 'Terms of Service', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last updated: December 2024\n', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
        Text('1. Acceptance of Terms', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Text('By accessing and using GlowCart, you accept and agree to be bound by the terms and provision of this agreement.', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        Text('2. Use License', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Text('Permission is granted to temporarily use GlowCart for personal, non-commercial transitory viewing only.', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        Text('3. Disclaimer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Text('The materials on GlowCart are provided on an "as is" basis. GlowCart makes no warranties, expressed or implied.', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        const SizedBox(height: 24),
      ],
    ));
  }

  void _showPrivacySheet(BuildContext context) {
    _showBottomSheet(context, 'Privacy Policy', Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last updated: December 2024\n', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
        Text('Information We Collect', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Text('We collect information you provide directly to us, such as when you create an account, make a purchase, or contact us for support.', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        Text('How We Use Your Information', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Text('We use the information we collect to provide, maintain, and improve our services, process transactions, and send you related information.', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        Text('Data Security', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        Text('We take reasonable measures to help protect information about you from loss, theft, misuse, and unauthorized access.', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        const SizedBox(height: 24),
      ],
    ));
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsItem({required this.icon, required this.label, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.black, size: 20)),
      title: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
      trailing: trailing ?? Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    );
  }
}
