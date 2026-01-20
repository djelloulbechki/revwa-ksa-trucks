import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constants/truck_types.dart';
import '../constants/regions.dart';
import '../main.dart';
import 'home_dashboard.dart';

class DriverInfoPage extends StatefulWidget {
  final String phone;

  const DriverInfoPage({super.key, required this.phone});

  @override
  State<DriverInfoPage> createState() => _DriverInfoPageState();
}

class _DriverInfoPageState extends State<DriverInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedRegion;
  String? _selectedGovernorate;
  List<String> _currentGovernorates = [];

  String _truckType = truckTypes.first;
  int _manufacturingYear = DateTime.now().year;

  bool _isLoading = false;
  String _message = '';

  void _updateGovernorates(String? region) {
    setState(() {
      _selectedGovernorate = null;
      _currentGovernorates = saudiRegions[region] ?? [];
    });
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = '';
    });

    final completeUrl = Uri.parse('https://revwa.cloud/webhook/driver-registration');

    try {
      final response = await http.post(
        completeUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': widget.phone,
          'name': _nameController.text.trim(),
          'region': _selectedRegion,
          'governorate': _selectedGovernorate,
          'truck_type': _truckType,
          'manufacturing_year': _manufacturingYear,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _message = data['message'] ?? 'تم التسجيل بنجاح!';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم التسجيل بنجاح! تحقق من رصيدك 100 ريال مجاني 🎁'),
            backgroundColor: Colors.green,
          ),
        );

        //Navigator.of(context).pushReplacementNamed('/homeDashboard');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeDashboard(driverPhone: widget.phone),
          ),
        );
      } else {
        _message = data['message'] ?? 'خطأ في التسجيل';
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
        title: const Text('كمل بياناتك'),
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
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'كمل بياناتك عشان تبدأ تستقبل طلبات!',
                  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'الاسم الكامل *',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value?.trim().isEmpty ?? true ? 'الرجاء إدخال الاسم' : null,
                ),
                const SizedBox(height: 20),

                // المنطقة
                DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  hint: const Text('اختر المنطقة *', style: TextStyle(color: Colors.white)),
                  decoration: InputDecoration(
                    labelText: 'المنطقة *',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: const Color(0xFF1E4D2B),
                  style: const TextStyle(color: Colors.white),
                  items: saudiRegions.keys.map((region) {
                    return DropdownMenuItem(value: region, child: Text(region));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRegion = value;
                      _updateGovernorates(value);
                    });
                  },
                  validator: (value) => value == null ? 'الرجاء اختيار المنطقة' : null,
                ),
                const SizedBox(height: 20),

                // المحافظة (تظهر فقط بعد اختيار المنطقة)
                DropdownButtonFormField<String>(
                  value: _selectedGovernorate,
                  hint: const Text('اختر المحافظة *', style: TextStyle(color: Colors.white)),
                  decoration: InputDecoration(
                    labelText: 'المحافظة *',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: const Color(0xFF1E4D2B),
                  style: const TextStyle(color: Colors.white),
                  items: _currentGovernorates.map((gov) {
                    return DropdownMenuItem(value: gov, child: Text(gov));
                  }).toList(),
                  onChanged: _currentGovernorates.isEmpty ? null : (value) {
                    setState(() {
                      _selectedGovernorate = value;
                    });
                  },
                  validator: _currentGovernorates.isEmpty
                      ? null
                      : (value) => value == null ? 'الرجاء اختيار المحافظة' : null,
                ),
                const SizedBox(height: 20),

                // نوع الشاحنة
                DropdownButtonFormField<String>(
                  value: _truckType,
                  decoration: InputDecoration(
                    labelText: 'نوع الشاحنة أو المعدة *',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: const Color(0xFF1E4D2B),
                  style: const TextStyle(color: Colors.white),
                  items: truckTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _truckType = value!;
                    });
                  },
                  validator: (value) => value == null ? 'الرجاء اختيار نوع الشاحنة' : null,
                ),
                const SizedBox(height: 20),

                // سنة التصنيع
                DropdownButtonFormField<int>(
                  value: _manufacturingYear,
                  decoration: InputDecoration(
                    labelText: 'سنة التصنيع *',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: const Color(0xFF1E4D2B),
                  style: const TextStyle(color: Colors.white),
                  items: List.generate(41, (index) => DateTime.now().year - index)
                      .map((year) => DropdownMenuItem(value: year, child: Text(year.toString())))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _manufacturingYear = value!;
                    });
                  },
                  validator: (value) => value == null ? 'الرجاء اختيار سنة التصنيع' : null,
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      'تسجيل الآن',
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
      ),
    );
  }
}