import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'driver_info_page.dart';
import 'driver_phone_page.dart';

class DriverOtpPage extends StatefulWidget {
  final String phone;

  const DriverOtpPage({super.key, required this.phone});

  @override
  State<DriverOtpPage> createState() => _DriverOtpPageState();
}

class _DriverOtpPageState extends State<DriverOtpPage> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      setState(() {
        _message = 'الرجاء إدخال كود مكون من 6 أرقام';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    final verifyUrl = Uri.parse('https://revwa.cloud/webhook/driver-otp-verify');

    try {
      final response = await http.post(
        verifyUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': widget.phone,
          'otp_code': _otpController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // التحقق ناجح – n8n هو اللي بيقرر الـ action
        final String action = data['action'] ?? 'open_info_page';

        if (action == 'open_dashboard') {
          // السائق موجود من قبل → داشبورد مباشرة
          Navigator.of(context).pushReplacementNamed('/homeDashboard',arguments: widget.phone,);// نمرر الرقم);
        } else {
          // سائق جديد → صفحة كمل البيانات
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DriverInfoPage(phone: widget.phone),
            ),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'تم التحقق بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // الكود خطأ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الكود غير صحيح أو منتهي الصلاحية، جرب تاني برقم جديد'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const DriverPhonePage(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الاتصال: $e'),
          backgroundColor: Colors.red,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const DriverPhonePage(),
        ),
      );
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
        title: const Text('أدخل الكود'),
        backgroundColor: const Color(0xFF1E4D2B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E4D2B), Color(0xFF0D3B1E)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'الكود المرسل إلى ${widget.phone}',
                style: const TextStyle(fontSize: 20, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, color: Colors.white, letterSpacing: 16),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '',
                  hintText: '------',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 32, letterSpacing: 16),
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'تحقق',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _message,
                style: TextStyle(
                  color: _message.contains('نجاح') ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}