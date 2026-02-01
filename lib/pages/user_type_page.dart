import 'package:flutter/material.dart';
import 'driver_phone_page.dart';
import 'CustomerPhonePage.dart';

class UserTypePage extends StatelessWidget {
  const UserTypePage({super.key});

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: h * 0.05),

                Icon(
                  Icons.local_shipping_rounded,
                  size: (w * 0.18).clamp(50, 80),
                  color: const Color(0xFF2ECC71),
                ),

                SizedBox(height: h * 0.015),

                Text(
                  'KSA TRUCKS',
                  style: TextStyle(
                    fontSize: (w * 0.1).clamp(26, 46),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),

                SizedBox(height: h * 0.05),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.08),
                  child: Column(
                    children: [
                      _buildSectionHeader(
                        "للسائقين وأصحاب الشاحنات",
                        "For Drivers & Truck Owners",
                        w,
                      ),
                      SizedBox(height: h * 0.02),
                      _buildDriverRegisterButton(context, h, w),
                      SizedBox(height: h * 0.02),
                      _buildDoubleBonusBanner(w),
                    ],
                  ),
                ),

                SizedBox(height: (h * 0.04).clamp(20, 40)),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.08),
                  child: Column(
                    children: [
                      _buildSectionHeader(
                        "للتجار وأصحاب البضائع",
                        "For Merchants & Cargo Owners",
                        w,
                      ),
                      SizedBox(height: h * 0.015),
                      _buildCustomerSection(context, h),
                    ],
                  ),
                ),

                SizedBox(height: h * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String ar, String en, double w) {
    return Column(
      children: [
        Text(
          ar,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: (w * 0.045).clamp(16, 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          en,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: (w * 0.035).clamp(12, 15),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverRegisterButton(
      BuildContext context, double h, double w) {
    return SizedBox(
      width: double.infinity,
      height: (h * 0.15).clamp(95, 130),
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DriverPhonePage()),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2ECC71),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: w * 0.03),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: (w * 0.12).clamp(35, 50),
              color: Colors.white,
            ),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سجل هنا للعمل',
                    style: TextStyle(
                      fontSize: (w * 0.055).clamp(18, 24),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'REGISTER TO WORK',
                    style: TextStyle(
                      fontSize: (w * 0.04).clamp(13, 17),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'أنا صاحب شاحنة | I have a Truck',
                    style: TextStyle(
                      fontSize: (w * 0.032).clamp(10, 12),
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoubleBonusBanner(double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: w * 0.04,
        horizontal: w * 0.03,
      ),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: const [
          _BonusRow(
            icon: Icons.stars_rounded,
            text: "رصيد 100 ريال هدية عند التسجيل",
          ),
          SizedBox(height: 8),
          _BonusRow(
            icon: Icons.card_giftcard_rounded,
            text: "100 SAR BONUS ON REGISTRATION",
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(BuildContext context, double h) {
    return SizedBox(
      width: double.infinity,
      height: (h * 0.110).clamp(60, 75),
      child: OutlinedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomerPhonePage()),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2ECC71), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "أبحث عن شاحنة (تحميل بضاعة)",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "I NEED A TRUCK (CARGO OWNER)",
              style: TextStyle(
                color: Color(0xFF2ECC71),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BonusRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BonusRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Color(0xFF1E4D2B), size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1E4D2B),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
