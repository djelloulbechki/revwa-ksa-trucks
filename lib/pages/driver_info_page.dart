import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constants/truck_types.dart';
import '../constants/regions.dart';
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

    try {
      final response = await http.post(
        Uri.parse('https://revwa.cloud/webhook/driver-registration'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': widget.phone,
          'name': _nameController.text.trim(),
          'region': _selectedRegion,
          'governorate': _selectedGovernorate,
          'truck_type': _truckType,
          'manufacturing_year': _manufacturingYear,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        _showSnackBar('تم التسجيل بنجاح! تحقق من رصيدك 100 ريال مجاني 🎁', Colors.green);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeDashboard(driverPhone: widget.phone)),
        );
      } else {
        setState(() => _message = data['message'] ?? 'خطأ في التسجيل');
      }
    } catch (e) {
      setState(() => _message = 'خطأ في الاتصال بالشبكة');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textAlign: TextAlign.right), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('إكمال البيانات', style: TextStyle(fontWeight: FontWeight.bold)),
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
              padding: EdgeInsets.symmetric(horizontal: isTablet ? size.width * 0.2 : 24.0, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(Icons.person_add_alt_1, size: 70, color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      'كمل بياناتك وابدأ العمل فوراً',
                      style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // الاسم الكامل
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('الاسم الكامل *', Icons.person),
                      validator: (value) => value?.trim().isEmpty ?? true ? 'الرجاء إدخال الاسم' : null,
                    ),
                    const SizedBox(height: 15),

                    // المنطقة
                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      dropdownColor: const Color(0xFF1E4D2B),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('المنطقة *', Icons.map),
                      items: saudiRegions.keys.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedRegion = v;
                          _updateGovernorates(v);
                        });
                      },
                      validator: (value) => value == null ? 'الرجاء اختيار المنطقة' : null,
                    ),
                    const SizedBox(height: 15),

                    // المحافظة
                    DropdownButtonFormField<String>(
                      value: _selectedGovernorate,
                      dropdownColor: const Color(0xFF1E4D2B),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('المحافظة *', Icons.location_city),
                      items: _currentGovernorates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: _currentGovernorates.isEmpty ? null : (v) => setState(() => _selectedGovernorate = v),
                      validator: (value) => _currentGovernorates.isNotEmpty && value == null ? 'الرجاء اختيار المحافظة' : null,
                    ),
                    const SizedBox(height: 15),

                    // نوع الشاحنة
                    DropdownButtonFormField<String>(
                      value: _truckType,
                      dropdownColor: const Color(0xFF1E4D2B),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('نوع الشاحنة *', Icons.local_shipping),
                      items: truckTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _truckType = v!),
                    ),
                    const SizedBox(height: 15),

                    // سنة التصنيع
                    DropdownButtonFormField<int>(
                      value: _manufacturingYear,
                      dropdownColor: const Color(0xFF1E4D2B),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('سنة التصنيع *', Icons.calendar_today),
                      items: List.generate(41, (i) => DateTime.now().year - i)
                          .map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                      onChanged: (v) => setState(() => _manufacturingYear = v!),
                    ),

                    const SizedBox(height: 40),

                    // الزر مع حل مشكلة النص الغارق
                    SizedBox(
                      width: double.infinity,
                      height: 65,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _completeRegistration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 4,
                          padding: EdgeInsets.zero,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 28, width: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : const Center(
                          child: Text(
                            'تسجيل الآن',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.0),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(_message, style: const TextStyle(color: Colors.orangeAccent)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.12),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.white54, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }
}