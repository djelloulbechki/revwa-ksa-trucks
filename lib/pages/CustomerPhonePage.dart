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
    // أضف دول تانية لو عايز
  };

  String selectedCountry = 'السعودية';
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    final phoneText = _phoneController.text.trim();

    if (phoneText.isEmpty || phoneText.length < 9 || phoneText.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال رقم جوال صحيح (9 أو 10 أرقام)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(phoneText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرقم يجب أن يحتوي على أرقام فقط'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final String countryCode = countryCodes[selectedCountry]!;
    final String fullPhone = countryCode + phoneText;

    try {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إرسال الكود: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'أهلاً بك في ريڤوا',
                  style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'أدخل رقم جوالك عشان نبدأ',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),

                DropdownButtonFormField<String>(
                  value: selectedCountry,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    labelText: 'اختر الدولة',
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  dropdownColor: const Color(0xFF1E4D2B),
                  style: const TextStyle(color: Colors.white),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
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

                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, color: Colors.white, letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: 'XXXXXXXXX',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 28),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    counterText: '',
                    prefixText: countryCodes[selectedCountry]! + '  ',
                    prefixStyle: const TextStyle(color: Colors.white70, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'إرسال الكود',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
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