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
    '+966': 'السعودية', '+213': 'الجزائر', '+965': 'الكويت',
    '+971': 'الإمارات', '+974': 'قطر', '+973': 'البحرين',
    '+968': 'عمان', '+20': 'مصر', '+962': 'الأردن',
    '+963': 'سوريا', '+964': 'العراق',
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
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;

    return Scaffold(
      // استخدام AppBar شفاف ليعطي مظهراً عصرياً مع التدرج اللوني
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('تسجيل دخول السائق', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              padding: EdgeInsets.symmetric(horizontal: isTablet ? size.width * 0.2 : 24.0),
              child: Column(
                children: [
                  const Icon(Icons.local_shipping, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    'Rewwa Logistics',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'سنرسل كود التحقق على واتساب',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // كود الدولة
                  DropdownButtonFormField<String>(
                    value: _selectedCountryCode,
                    decoration: _inputDecoration('كود الدولة'),
                    dropdownColor: const Color(0xFF1E4D2B),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    items: countryCodes.entries.map((e) => DropdownMenuItem(
                      value: e.key, child: Text('${e.key} ${e.value}'),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedCountryCode = v!),
                  ),
                  const SizedBox(height: 20),

                  // رقم الجوال
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 9,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                    textAlign: TextAlign.center,
                    decoration: _inputDecoration('رقم الجوال (9 أرقام)').copyWith(
                      hintText: '545375261',
                      hintStyle: const TextStyle(color: Colors.white24),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'مثال: 545375261 (بدون 0 في البداية)',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 50),

                  // الزر (تم حل مشكلة النص الغارق هنا)
                  SizedBox(
                    width: double.infinity,
                    height: 65, // زيادة الارتفاع قليلاً لراحة العين
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _triggerWebhook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 4,
                        padding: EdgeInsets.zero, // لضمان توسط النص
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 28, width: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : const Center(
                        child: Text(
                          'إرسال كود التحقق على واتساب',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            height: 1.0, // حل مشكلة "غرق" النص العربي
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  if (_message.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _message,
                        style: TextStyle(color: _message.contains('تم') ? Colors.greenAccent : Colors.orangeAccent),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.12),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 1)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    );
  }
}