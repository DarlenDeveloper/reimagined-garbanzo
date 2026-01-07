import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';

class RunnerCodeScreen extends StatefulWidget {
  const RunnerCodeScreen({super.key});

  @override
  State<RunnerCodeScreen> createState() => _RunnerCodeScreenState();
}

class _RunnerCodeScreenState extends State<RunnerCodeScreen> {
  final List<TextEditingController> _codeControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _codeControllers.map((c) => c.text).join();

  void _onCodeChanged(int index, String value) {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });

    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_code.length == 4) {
      _verifyCode();
    }
  }

  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_codeControllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_code.length != 4) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await Future.delayed(const Duration(seconds: 2));

    // Dummy validation - accept "1234" as valid
    if (_code == '1234') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome! You now have access to "My Awesome Store"', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.go('/dashboard');
      }
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Invalid or expired code. Please ask your admin for a new code.';
      });
      for (var controller in _codeControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  void _clearCode() {
    for (var controller in _codeControllers) {
      controller.clear();
    }
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () => context.go('/account-type'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.key, size: 36, color: Colors.black),
              ),
              const SizedBox(height: 24),
              Text(
                'Join Store',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 4-digit code from your\nstore administrator',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // Code input
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    width: 64,
                    height: 72,
                    margin: EdgeInsets.only(right: index < 3 ? 12 : 0),
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (event) => _onKeyPressed(index, event),
                      child: TextField(
                        controller: _codeControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: _hasError ? Colors.red[50] : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _hasError ? Colors.red : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _hasError ? Colors.red : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) => _onCodeChanged(index, value),
                      ),
                    ),
                  );
                }),
              ),
              if (_hasError && _errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.warning_2, color: Colors.red[700], size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _isLoading ? null : _verifyCode,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey[400] : Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'Join Store',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _clearCode,
                child: Text('Clear Code', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 40),
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.info_circle, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 10),
                        Text('How to get a code', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoStep(number: '1', text: 'Ask your store admin to add you to the team'),
                    const SizedBox(height: 8),
                    _InfoStep(number: '2', text: 'They will give you a 4-digit code'),
                    const SizedBox(height: 8),
                    _InfoStep(number: '3', text: 'Enter the code here within 15 minutes'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Want to create your own store? ", style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14)),
                  GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: Text('Sign Up', style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  final String number;
  final String text;

  const _InfoStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
          child: Center(
            child: Text(number, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600], height: 1.4)),
        ),
      ],
    );
  }
}
