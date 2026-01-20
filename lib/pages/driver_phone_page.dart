import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'driver_otp_page.dart';

class DriverPhonePage extends StatefulWidget {
  const DriverPhonePage({super.key});

  @override
  State<DriverPhonePage> createState() => _DriverPhonePageState();
}

class _DriverPhonePageState extends State<DriverPhonePage> {
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+966';
  bool _isLoading = false;
  String _message = '';

  final Map<String, String> countryCodes = {
    '+966': 'السعودية',
    '+213': 'الجزائر',
    '+965': 'الكويت',
    '+971': 'الإمارات',
    '+974': 'قطر',
    '+973': 'البحرين',
    '+968': 'عمان',
    '+20': 'مصر',
    '+962': 'الأردن',
    '+963': 'سوريا',
    '+964': 'العراق',
  };

  Future<void> _triggerWebhook() async {
    final phone = _phoneController.text.trim();

    if (phone.length != 9 ||
        phone.startsWith('0') ||
        !RegExp(r'^[1-9]\d{8}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال رقم جوال صحيح مكون من 9 أرقام (لا يبدأ بصفر)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    final fullPhone = '$_selectedCountryCode$phone';
    final webhookUrl = Uri.parse('https://revwa.cloud/webhook/driver-phone-otp-gen');

    try {
      final response = await http.post(
        webhookUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': fullPhone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _message = data['message'] ?? 'تم إرسال الكود على واتساب!';
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DriverOtpPage(phone: fullPhone),
          ),
        );
      } else {
        _message = 'خطأ في الإرسال: ${response.statusCode}';
      }
    } catch (e) {
      _message = 'خطأ في الاتصال: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أدخل رقم واتسابك'),
        backgroundColor: const Color(0xFF1E4D2B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E4D2B),
              Color(0xFF0D3B1E),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'سنرسل كود التحقق على واتساب',
                  style: TextStyle(fontSize: 20, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                DropdownButtonFormField<String>(
                  value: _selectedCountryCode,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    labelText: 'كود الدولة',
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  dropdownColor: const Color(0xFF1E4D2B),
                  style: const TextStyle(color: Colors.white),
                  items: countryCodes.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text('${entry.key} ${entry.value}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountryCode = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    hintText: '545375261',
                    hintStyle: const TextStyle(color: Colors.white54, fontSize: 24),
                    counterText: '',
                    labelText: 'رقم الجوال (9 أرقام)',
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'مثال: 545375261 (بدون 0 في البداية)',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _triggerWebhook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'إرسال كود التحقق على واتساب',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _message,
                  style: TextStyle(
                    color: _message.contains('تم') ? Colors.green : Colors.red,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
