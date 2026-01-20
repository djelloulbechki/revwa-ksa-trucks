import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:google_place/google_place.dart';

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

  double? _latitude;
  double? _longitude;
  double? _toLatitude;
  double? _toLongitude;

  bool _isLoading = false;

  final List<String> truckTypes = [
    'تريلا صندوق',
    'تريلا سطحه',
    'دينا',
    'قلاب',
    'براد',
    'تانكر',
    'لو بد',
    'معدات ثقيلة',
  ];

  Future<void> _pickLocation(
      TextEditingController controller, bool isFromLocation) async {
    final gmap.LatLng? pickedLatLng = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerPage()),
    );

    if (pickedLatLng != null) {
      try {
        final placemarks = await placemarkFromCoordinates(
          pickedLatLng.latitude,
          pickedLatLng.longitude,
        );

        String address = "موقع مخصص";
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          address = [
            p.locality,
            p.subLocality,
            p.administrativeArea,
          ].where((e) => e != null && e.isNotEmpty).join(' - ');
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
      } catch (_) {
        controller.text = "موقع مخصص";
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تحديد مكان التحميل')),
      );
      return;
    }

    if (_toLatitude == null || _toLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تحديد مكان التفريغ')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final url =
    Uri.parse('https://revwa.cloud/webhook/client-order-draft');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': widget.phone,
          'from_city': _fromCityController.text.trim(),
          'to_city': _toCityController.text.trim(),
          'required_truck_type': _truckType,
          'required_trucks_count': _requiredTrucksCount,
          'min_manufacturing_year': _minManufacturingYear,
          'load_details': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          'from_latitude': _latitude,
          'from_longitude': _longitude,
          'to_latitude': _toLatitude,
          'to_longitude': _toLongitude,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلبك بنجاح 🚛'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'فشل في الإرسال')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الاتصال: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildDropdown<T>(
      String label, T value, List<T> items, ValueChanged<T?> onChanged) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: _buildInputDecoration(label, Icons.list),
      dropdownColor: const Color(0xFF1E4D2B),
      style: const TextStyle(color: Colors.white),
      items: items
          .map((i) =>
          DropdownMenuItem(value: i, child: Text(i.toString())))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildYearDropdown() {
    return DropdownButtonFormField<int>(
      value: _minManufacturingYear,
      hint: const Text('أدنى سنة تصنيع',
          style: TextStyle(color: Colors.white70)),
      decoration:
      _buildInputDecoration('أدنى سنة تصنيع', Icons.calendar_today),
      dropdownColor: const Color(0xFF1E4D2B),
      style: const TextStyle(color: Colors.white),
      items: List.generate(30, (i) => DateTime.now().year - i)
          .map((y) =>
          DropdownMenuItem(value: y, child: Text(y.toString())))
          .toList(),
      onChanged: (val) => setState(() => _minManufacturingYear = val),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب شحن جديد'),
        backgroundColor: const Color(0xFF1E4D2B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _fromCityController,
                readOnly: true,
                onTap: () => _pickLocation(_fromCityController, true),
                decoration:
                _buildInputDecoration('من أين *', Icons.location_on),
                validator: (v) =>
                v!.isEmpty ? 'حدد موقع التحميل' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _toCityController,
                readOnly: true,
                onTap: () => _pickLocation(_toCityController, false),
                decoration:
                _buildInputDecoration('إلى أين *', Icons.flag),
                validator: (v) =>
                v!.isEmpty ? 'حدد موقع التفريغ' : null,
              ),
              const SizedBox(height: 16),
              _buildDropdown<String>('نوع الشاحنة', _truckType,
                  truckTypes, (v) => setState(() => _truckType = v!)),
              const SizedBox(height: 16),
              _buildDropdown<int>(
                  'عدد الشاحنات',
                  _requiredTrucksCount,
                  List.generate(20, (i) => i + 1),
                      (v) => setState(() => _requiredTrucksCount = v!)),
              const SizedBox(height: 16),
              _buildYearDropdown(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: _buildInputDecoration(
                    'تفاصيل إضافية', Icons.note),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('إرسال الطلب'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= MAP PICKER ================= */

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

  @override
  void initState() {
    super.initState();
    _googlePlace = GooglePlace(kGoogleApiKey);
    _initLocation();
  }

  Future<void> _initLocation() async {
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _currentCenter = gmap.LatLng(pos.latitude, pos.longitude);
      _selectedLatLng = _currentCenter;
    });
  }

  Future<void> _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    final res = await _googlePlace.autocomplete.get(
      value,
      components: [Component('country', 'sa')],
    );

    if (res != null && res.predictions != null) {
      setState(() => _predictions = res.predictions!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حدد الموقع')),
      body: Stack(
        children: [
          gmap.GoogleMap(
            onMapCreated: (c) => _mapController = c,
            initialCameraPosition:
            gmap.CameraPosition(target: _currentCenter, zoom: 15),
            onCameraMove: (pos) {
              _selectedLatLng = pos.target;
            },
            myLocationEnabled: true,
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن موقع',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                if (_predictions.isNotEmpty)
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      itemBuilder: (c, i) {
                        final p = _predictions[i];
                        return ListTile(
                          title: Text(p.description ?? ''),
                          onTap: () async {
                            final d =
                            await _googlePlace.details.get(p.placeId!);
                            final loc = d!.result!.geometry!.location!;
                            final latLng =
                            gmap.LatLng(loc.lat!, loc.lng!);

                            _mapController.animateCamera(
                              gmap.CameraUpdate.newLatLngZoom(latLng, 16),
                            );

                            setState(() {
                              _currentCenter = latLng;
                              _selectedLatLng = latLng;
                              _predictions = [];
                              _searchController.text =
                                  p.description ?? '';
                            });
                          },
                        );
                      },
                    ),
                  )
              ],
            ),
          ),
          const Center(
              child:
              Icon(Icons.location_on, color: Colors.red, size: 40)),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, _selectedLatLng ?? _currentCenter),
              child: const Text('تأكيد الموقع'),
            ),
          )
        ],
      ),
    );
  }
}
