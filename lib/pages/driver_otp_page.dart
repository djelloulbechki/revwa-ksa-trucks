import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'driver_info_page.dart';
import 'home_dashboard.dart';

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
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnackBar('الرجاء إدخال كود مكون من 6 أرقام', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://revwa.cloud/webhook/driver-otp-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': widget.phone, 'otp_code': otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userType', 'driver');
        await prefs.setString('userPhone', widget.phone);

        if (data['action'] == 'open_dashboard') {
          Navigator.pushReplacementNamed(context, '/homeDashboard', arguments: widget.phone);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => DriverInfoPage(phone: widget.phone)),
          );
        }
      } else {
        setState(() {
          _message = 'الكود غير صحيح أو منتهي الصلاحية، جرب ثاني';
        });
        _showSnackBar(_message, Colors.red);
      }
    } catch (e) {
      setState(() {
        _message = 'خطأ في الاتصال بالسيرفر';
      });
      _showSnackBar(_message, Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, textAlign: TextAlign.right),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double h = size.height;
    final double w = size.width;

    return Scaffold(
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: h * 0.10),

                  // أيقونة كبيرة
                  Icon(
                    Icons.lock_outline_rounded,
                    size: (w * 0.20).clamp(80, 120),
                    color: const Color(0xFF2ECC71),
                  ),

                  SizedBox(height: h * 0.04),

                  // العنوان
                  Text(
                    'تأكيد رقم الهاتف',
                    style: TextStyle(
                      fontSize: (w * 0.08).clamp(28, 40),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: h * 0.01),

                  // وصف
                  Text(
                    'أدخل الكود المرسل إلى ${widget.phone}',
                    style: TextStyle(
                      fontSize: (w * 0.045).clamp(16, 20),
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: h * 0.06),

                  // حقل OTP أنيق
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 12,
                      ),
                      maxLength: 6,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        hintText: '------',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 32),
                      ),
                    ),
                  ),

                  SizedBox(height: h * 0.05),

                  // زر التحقق الكبير
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 8,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                          : const Text(
                        'تحقق من الكود',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // رسالة خطأ أو نجاح
                  if (_message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        _message,
                        style: TextStyle(
                          color: _message.contains('نجاح') ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  SizedBox(height: h * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}