import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'customer_dashboard.dart'; // تأكد من الاسم الصحيح

class CustomerOtpPage extends StatefulWidget {
  final String phone;

  const CustomerOtpPage({super.key, required this.phone});

  @override
  State<CustomerOtpPage> createState() => _CustomerOtpPageState();
}

class _CustomerOtpPageState extends State<CustomerOtpPage> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال كود مكون من 6 أرقام'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://revwa.cloud/webhook/client-otp-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': widget.phone,
          'otp_code': _otpController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // التحقق ناجح → نفتح الداشبورد مباشرة
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CustomerDashboard(phone: widget.phone),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الكود غير صحيح أو منتهي الصلاحية، جرب تاني'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الاتصال: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
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
                  'أدخل الكود المرسل',
                  style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'الكود المرسل إلى ${widget.phone}',
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
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
                    onPressed: _isLoading ? null : _verifyOtp,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}