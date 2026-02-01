import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:google_place/google_place.dart';

// تأكد من وضع مفتاحك الصحيح هنا
const kGoogleApiKey = "AIzaSyBKZqHf1CRTo6AJjZghfi9SmWCfTs5-X20";

class CustomerRequestPage extends StatefulWidget {
  final String phone;
  const CustomerRequestPage({super.key, required this.phone});

  @override
  State<CustomerRequestPage> createState() => _CustomerRequestPageState();
}

class _CustomerRequestPageState extends State<CustomerRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _fromCityController = TextEditingController();
  final _toCityController = TextEditingController();
  final _notesController = TextEditingController();

  String _truckType = 'تريلا صندوق';
  int _requiredTrucksCount = 1;
  int? _minManufacturingYear;

  double? _latitude, _longitude, _toLatitude, _toLongitude;
  bool _isLoading = false;

  final List<String> truckTypes = [
    'تريلا صندوق', 'تريلا سطحه', 'دينا', 'قلاب', 'براد', 'تانكر', 'لو بد', 'معدات ثقيلة',
  ];

  Future<void> _pickLocation(TextEditingController controller, bool isFromLocation) async {
    final gmap.LatLng? pickedLatLng = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerPage()),
    );

    if (pickedLatLng != null) {
      try {
        // الحل: استدعاء مباشر بدون اسم المعامل لتجنب خطأ الإصدارات
        List<Placemark> placemarks = await placemarkFromCoordinates(
          pickedLatLng.latitude,
          pickedLatLng.longitude,
        );

        String address = "موقع مخصص";
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          // ترتيب العناوين: الحي - المدينة
          address = [p.subLocality, p.locality]
              .where((e) => e != null && e.isNotEmpty)
              .join(' - ');

          if (address.isEmpty) address = p.administrativeArea ?? "موقع مخصص";
        }

        setState(() {
          controller.text = address;
          if (isFromLocation) {
            _latitude = pickedLatLng.latitude;
            _longitude = pickedLatLng.longitude;
          } else {
            _toLatitude = pickedLatLng.latitude;
            _toLongitude = pickedLatLng.longitude;
          }
        });
      } catch (e) {
        debugPrint("Geocoding Error: $e");
        controller.text = "موقع مخصص";
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _toLatitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد المواقع على الخريطة')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://revwa.cloud/webhook/client-order-draft'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': widget.phone,
          'from_city': _fromCityController.text.trim(),
          'to_city': _toCityController.text.trim(),
          'required_truck_type': _truckType,
          'required_trucks_count': _requiredTrucksCount,
          'min_manufacturing_year': _minManufacturingYear,
          'load_details': _notesController.text.trim(),
          'from_latitude': _latitude,
          'from_longitude': _longitude,
          'to_latitude': _toLatitude,
          'to_longitude': _toLongitude,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلبك بنجاح 🚛'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الاتصال: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: const Color(0xFF2ECC71)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E4D2B),
      appBar: AppBar(title: const Text('طلب جديد'), backgroundColor: Colors.transparent, elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _fromCityController, readOnly: true,
              onTap: () => _pickLocation(_fromCityController, true),
              style: const TextStyle(color: Colors.white),
              decoration: _inputStyle('نقطة التحميل *', Icons.location_on),
              validator: (v) => v!.isEmpty ? 'حدد الموقع' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _toCityController, readOnly: true,
              onTap: () => _pickLocation(_toCityController, false),
              style: const TextStyle(color: Colors.white),
              decoration: _inputStyle('نقطة التفريغ *', Icons.flag),
              validator: (v) => v!.isEmpty ? 'حدد الموقع' : null,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _truckType,
              dropdownColor: const Color(0xFF0D3B1E),
              style: const TextStyle(color: Colors.white),
              decoration: _inputStyle('نوع الشاحنة', Icons.local_shipping),
              items: truckTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _truckType = v!),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<int>(
              value: _requiredTrucksCount,
              dropdownColor: const Color(0xFF0D3B1E),
              style: const TextStyle(color: Colors.white),
              decoration: _inputStyle('عدد الشاحنات', Icons.format_list_numbered),
              items: List.generate(10, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))).toList(),
              onChanged: (v) => setState(() => _requiredTrucksCount = v!),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _notesController, maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: _inputStyle('ملاحظات إضافية', Icons.note_add),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('إرسال الطلب الآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}


/* ================= MAP PICKER المحسن والمتجاوب ================= */

/* ================= MAP PICKER المحسن مع اقتراحات فورية ================= */

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});
  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  gmap.LatLng _currentCenter = const gmap.LatLng(24.7136, 46.6753);
  gmap.LatLng? _selectedLatLng;
  late gmap.GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  late GooglePlace _googlePlace;
  List<AutocompletePrediction> _predictions = [];
  bool _isSearching = false; // لمتابعة حالة البحث

  @override
  void initState() {
    super.initState();
    _googlePlace = GooglePlace(kGoogleApiKey);
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        _currentCenter = gmap.LatLng(pos.latitude, pos.longitude);
      });
      _mapController.animateCamera(gmap.CameraUpdate.newLatLng(_currentCenter));
    } catch (_) {}
  }

  // الدالة المسؤولة عن جلب الاقتراحات
  void _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final res = await _googlePlace.autocomplete.get(
        value,
        language: 'ar',
        components: [Component('country', 'sa')], // حصر البحث في السعودية لسرعة النتائج
      );

      if (res != null && res.predictions != null) {
        setState(() {
          _predictions = res.predictions!;
          _isSearching = false;
        });
      } else {
        setState(() => _isSearching = false);
      }
    } catch (e) {
      debugPrint("Autocomplete Error: $e");
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حدد الموقع'),
        backgroundColor: const Color(0xFF1E4D2B),
        elevation: 0,
      ),
      body: Stack(
        children: [
          gmap.GoogleMap(
            onMapCreated: (c) => _mapController = c,
            initialCameraPosition: gmap.CameraPosition(target: _currentCenter, zoom: 15),
            onCameraMove: (pos) => _selectedLatLng = pos.target,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            padding: const EdgeInsets.only(bottom: 120, top: 80),
          ),

          // حقل البحث الذكي
          Positioned(
            top: 15, left: 15, right: 15,
            child: Column(
              children: [
                Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(15),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن موقع (الرياض، حي النرجس...)',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF1E4D2B)),
                      // إضافة مؤشر تحميل صغير داخل الحقل عند البحث
                      suffixIcon: _isSearching
                          ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E4D2B)),
                      )
                          : (_searchController.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _searchController.clear();
                        setState(() => _predictions = []);
                      })
                          : null),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),

                // قائمة الاقتراحات (تظهر فقط عند وجود نتائج)
                if (_predictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _predictions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 50),
                      itemBuilder: (c, i) => ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.grey, size: 20),
                        title: Text(
                            _predictions[i].description ?? '',
                            style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500)
                        ),
                        onTap: () async {
                          final details = await _googlePlace.details.get(_predictions[i].placeId!, language: 'ar');
                          if (details != null && details.result != null) {
                            final loc = details.result!.geometry!.location!;
                            final target = gmap.LatLng(loc.lat!, loc.lng!);

                            _mapController.animateCamera(gmap.CameraUpdate.newLatLngZoom(target, 16));

                            setState(() {
                              _searchController.text = _predictions[i].description!;
                              _predictions = [];
                              _selectedLatLng = target;
                            });
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35),
              child: Icon(Icons.location_on, color: Colors.red, size: 50),
            ),
          ),

          Positioned(
            bottom: 30,
            left: screenWidth * 0.1,
            right: screenWidth * 0.1,
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selectedLatLng ?? _currentCenter),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: const Text(
                  'تأكيد الموقع المختار',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

