import 'package:flutter/material.dart';
import 'driver_phone_page.dart';
import 'CustomerPhonePage.dart';

class UserTypePage extends StatelessWidget {
  const UserTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب أبعاد الشاشة الحالية
    final size = MediaQuery.of(context).size;
    final double screenHeight = size.height;
    final double screenWidth = size.width;

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
              child: Padding(
                // جعل الحواف نسبية من عرض الشاشة (مثلاً 8% من العرض)
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // اللوجو والاسم - استخدام LayoutBuilder يجعله ذكي
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16, // المسافة بين الأيقونة والنص
                      children: [
                        Icon(
                          Icons.local_shipping,
                          // حجم الأيقونة نسبة إلى عرض الشاشة
                          size: screenWidth * 0.15 > 80 ? 80 : screenWidth * 0.15,
                          color: Colors.white,
                        ),
                        Text(
                          'Rewwa',
                          style: TextStyle(
                            // حجم الخط نسبة إلى عرض الشاشة
                            fontSize: screenWidth * 0.1,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    // مسافة متغيرة بناءً على ارتفاع الشاشة
                    SizedBox(height: screenHeight * 0.1),

                    // الأزرار
                    _buildUserButton(
                      context: context,
                      label: 'أنا سائق\nI am a Driver',
                      bgColor: Colors.white,
                      textColor: const Color(0xFF2ECC71),
                      screenHeight: screenHeight,
                      destination: const DriverPhonePage(),
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    _buildUserButton(
                      context: context,
                      label: 'أبغى شاحنة\nI Need a Truck',
                      bgColor: const Color(0xFF2ECC71),
                      textColor: Colors.white,
                      screenHeight: screenHeight,
                      destination: const CustomerPhonePage(),
                    ),

                    SizedBox(height: screenHeight * 0.05),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ميثود لبناء الزر بشكل ديناميكي لتقليل تكرار الكود
  Widget _buildUserButton({
    required BuildContext context,
    required String label,
    required Color bgColor,
    required Color textColor,
    required double screenHeight,
    required Widget destination,
  }) {
    return SizedBox(
      width: double.infinity,
      // ارتفاع الزر يمثل 15% من ارتفاع الشاشة بحد أقصى وأدنى
      height: (screenHeight * 0.15).clamp(80.0, 140.0),
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            // الخط يصغر ويكبر حسب حجم الشاشة
            fontSize: (screenHeight * 0.03).clamp(18.0, 26.0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}