import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  String _message = '';

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnackBar('الرجاء إدخال كود مكون من 6 أرقام', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://revwa.cloud/webhook/client-otp-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': widget.phone,
          'otp_code': otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // حفظ الجلسة في SharedPreferences عشان يفضل مفتوح دائمًا
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userType', 'customer');
        await prefs.setString('userPhone', widget.phone);

        // التنقل للداشبورد
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CustomerDashboard(phone: widget.phone),
            ),
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
        _message = 'خطأ في الاتصال بالسيرفر: $e';
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
    final bool isTablet = size.width > 600;
    final double horizontalPadding = isTablet ? size.width * 0.25 : 24.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'تأكيد الهوية',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'أدخل كود التحقق المرسل إلى\n${widget.phone}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),

                  // حقل إدخال الكود المحسن
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 36 : 30,
                      color: Colors.white,
                      letterSpacing: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: '000000',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.1),
                        letterSpacing: 15,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2),
                      ),
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 40),

                  // زر التحقق الكبير
                  SizedBox(
                    width: double.infinity,
                    height: 65,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 4,
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                            : const Text(
                          'تأكيد الرمز',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // خيار إعادة الإرسال
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      // هنا يمكنك استدعاء نفس الـ Webhook الخاص بإرسال الـ OTP
                      _showSnackBar('جاري إعادة إرسال الكود...', Colors.blueGrey);
                    },
                    child: const Text(
                      'لم يصلك الكود؟ إعادة إرسال',
                      style: TextStyle(color: Colors.white60, fontSize: 14),
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

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}