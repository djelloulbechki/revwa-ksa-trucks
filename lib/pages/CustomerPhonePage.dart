import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'customer_otp_page.dart';

class CustomerPhonePage extends StatefulWidget {
  const CustomerPhonePage({super.key});

  @override
  State<CustomerPhonePage> createState() => _CustomerPhonePageState();
}

class _CustomerPhonePageState extends State<CustomerPhonePage> {
  final _phoneController = TextEditingController();

  final Map<String, String> countryCodes = {
    'السعودية': '+966',
    'الإمارات': '+971',
    'الجزائر': '+213',
    'مصر': '+20',
    'الأردن': '+962',
    'المغرب': '+212',
  };

  String selectedCountry = 'السعودية';
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    final phoneText = _phoneController.text.trim();

    if (phoneText.isEmpty || phoneText.length < 9) {
      _showSnackBar('الرجاء إدخال رقم جوال صحيح', Colors.red);
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(phoneText)) {
      _showSnackBar('الرقم يجب أن يحتوي على أرقام فقط', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final String countryCode = countryCodes[selectedCountry]!;
    final String fullPhone = countryCode + phoneText;

    try {
      // إرسال الطلب للـ Webhook
      await http.post(
        Uri.parse('https://revwa.cloud/webhook/client-phone-otp-gen'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': fullPhone}),
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomerOtpPage(phone: fullPhone),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('خطأ في الاتصال بالسيرفر', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m, textAlign: TextAlign.right), backgroundColor: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;
    final double horizontalPadding = isTablet ? size.width * 0.25 : 24.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E4D2B), Color(0xFF0D3B1E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // اللوجو أو أيقونة ترحيبية
                  const Icon(Icons.vignette_outlined, size: 80, color: Colors.white24),
                  const SizedBox(height: 30),
                  const Text(
                    'أهلاً بك في ريڤوا',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'أدخل رقم جوالك لنبدأ الرحلة',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),

                  // اختيار الدولة بتصميم أرقى
                  DropdownButtonFormField<String>(
                    value: selectedCountry,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      labelText: 'اختر الدولة',
                      labelStyle: const TextStyle(color: Colors.white70),
                    ),
                    dropdownColor: const Color(0xFF1E4D2B),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    items: countryCodes.keys.map((String country) {
                      return DropdownMenuItem(value: country, child: Text(country));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCountry = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // حقل رقم الجوال مع تحسينات الوضوح
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 32 : 26,
                      color: Colors.white,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'XXXXXXXXX',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 24),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      counterText: '',
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              countryCodes[selectedCountry]!,
                              style: const TextStyle(color: Color(0xFF2ECC71), fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            Container(width: 1, height: 30, color: Colors.white24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // الزر الاحترافي
                  SizedBox(
                    width: double.infinity,
                    height: 65,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 5,
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'إرسال الكود',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.0, // حل مشكلة النصوص العربية
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'سيتم إرسال كود تفعيل عبر WhatsApp',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}