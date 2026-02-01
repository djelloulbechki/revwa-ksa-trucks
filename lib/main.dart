import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/user_type_page.dart';
import 'pages/home_dashboard.dart';
import 'pages/customer_dashboard.dart';

void main() async {
  // ضمان أن فلاتر بدأت قبل أي شيء
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة سوبابيز
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
      title: 'Revwa',
      debugShowCheckedModeBanner: false,
      home: const InitialAuthResolver(),

      // التعديل الجذري هنا: تعريف المسارات المفقودة
      routes: {
        '/userType': (context) => const UserTypePage(),

        // مسار لوحة تحكم السائق (تأكد من استقبال الهاتف كـ String)
        '/homeDashboard': (context) {
          final phone = ModalRoute.of(context)!.settings.arguments as String? ?? "";
          return HomeDashboard(driverPhone: phone);
        },

        // مسار لوحة تحكم العميل
        '/customerDashboard': (context) {
          final phone = ModalRoute.of(context)!.settings.arguments as String? ?? "";
          return CustomerDashboard(phone: phone);
        },
      },
    );
  }
}

class InitialAuthResolver extends StatefulWidget {
  const InitialAuthResolver({super.key});

  @override
  State<InitialAuthResolver> createState() => _InitialAuthResolverState();
}

class _InitialAuthResolverState extends State<InitialAuthResolver> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final String? userType = prefs.getString('userType');
      final String? phone = prefs.getString('userPhone');

      // فحص الحالة من سوبابيز اختيارياً
      // final session = Supabase.instance.client.auth.currentSession;

      if (isLoggedIn && userType != null && phone != null) {
        if (!mounted) return;

        if (userType == 'driver') {
          _navigate(HomeDashboard(driverPhone: phone));
        } else {
          _navigate(CustomerDashboard(phone: phone));
        }
        return;
      }

      _navigate(const UserTypePage());
    } catch (e) {
      _navigate(const UserTypePage());
    }
  }

  void _navigate(Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E4D2B),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
      ),
    );
  }
}