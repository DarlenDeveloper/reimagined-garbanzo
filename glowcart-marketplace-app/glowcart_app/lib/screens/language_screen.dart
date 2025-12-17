import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'en';

  final List<_Language> _languages = [
    _Language(code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸'),
    _Language(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    _Language(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    _Language(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    _Language(code: 'it', name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
    _Language(code: 'pt', name: 'Portuguese', nativeName: 'Português', flag: '🇵🇹'),
    _Language(code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
    _Language(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    _Language(code: 'ko', name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
    _Language(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBeige,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Language', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _languages.length,
        itemBuilder: (context, index) => _buildLanguageCard(_languages[index]),
      ),
    );
  }

  Widget _buildLanguageCard(_Language lang) {
    final isSelected = _selectedLanguage == lang.code;
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = lang.code),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkGreen.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(lang.flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  Text(lang.nativeName, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? AppColors.darkGreen : AppColors.surfaceVariant),
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Language {
  final String code, name, nativeName, flag;
  _Language({required this.code, required this.name, required this.nativeName, required this.flag});
}
