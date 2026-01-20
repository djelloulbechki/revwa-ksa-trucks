import 'package:flutter/material.dart';
import 'package:revwa_ksa_trucks/pages/CustomerPhonePage.dart';
import 'package:revwa_ksa_trucks/pages/customer_request_page.dart';
import 'pages/user_type_page.dart';
import 'pages/driver_phone_page.dart';
import 'pages/driver_otp_page.dart';
import 'pages/driver_info_page.dart';
import 'pages/home_dashboard.dart';
import 'pages/customer_otp_page.dart';
import 'pages/customer_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://idqcnmqzdgbdbvweozvp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkcWNubXF6ZGdiZGJ2d2VvenZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU5MTM2MDIsImV4cCI6MjA4MTQ4OTYwMn0.2h9b57R8CipYVfJN3aUxD6w6ARTn1xTEXcpLUucSklo',
  );

  runApp(const TruckApp());
}

class TruckApp extends StatelessWidget {
  const TruckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rewwa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1E4D2B),
        primaryColor: const Color(0xFF2ECC71),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2ECC71),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      initialRoute: '/', // صفحة اختيار النوع (سائق أو عميل)
      routes: {
        '/': (context) => const UserTypePage(),

        // طريق السائق (زي ما هو)
        '/driverPhone': (context) => const DriverPhonePage(),
        '/driverOtp': (context) {
          final String phone = ModalRoute.of(context)!.settings.arguments as String;
          return DriverOtpPage(phone: phone);
        },
        '/driverInfo': (context) {
          final String phone = ModalRoute.of(context)!.settings.arguments as String;
          return DriverInfoPage(phone: phone);
        },
        '/homeDashboard': (context) {
          final String phone = ModalRoute.of(context)!.settings.arguments as String;
          return HomeDashboard(driverPhone: phone);
        },

        // طريق العميل الجديد
        '/customerPhone': (context) => const CustomerPhonePage(),
        '/customerOtp': (context) {
          final String phone = ModalRoute.of(context)!.settings.arguments as String;
          return CustomerOtpPage(phone: phone);
        },
        '/customerDashboard': (context) {
          final String phone = ModalRoute.of(context)!.settings.arguments as String;
          return CustomerDashboard(phone: phone);
        },

        // صفحة طلب حمولة جديدة (من داخل الداشبورد)
        '/customerRequest': (context) => const CustomerRequestPage(phone: '',), // لو عايز نحتفظ بيها للطلب الجديد
      },
    );
  }
}