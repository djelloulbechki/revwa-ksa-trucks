import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeDashboard extends StatefulWidget {
  final String driverPhone;
  const HomeDashboard({super.key, required this.driverPhone});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? driver;
  String currentCity = 'جاري التحديد...';
  String truckType = 'غير محدد';
  List<Map<String, dynamic>> availableOrders = [];
  bool isLoading = true;
  bool isAvailable = false;
  bool isSwitchLoading = false;
  Timer? _locationTimer;
  StreamSubscription? _notificationsSub;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _notificationsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadDriverData() async {
    setState(() => isLoading = true);
    try {
      driver = await supabase
          .from('drivers')
          .select()
          .eq('phone', widget.driverPhone)
          .single();

      isAvailable = driver!['is_available'] == 'online';
      currentCity = driver!['current_city'] ?? 'غير محدد';

      final assignment = await supabase
          .from('driver_truck_assignments')
          .select('trucks(truck_type)')
          .eq('driver_id', driver!['id'])
          .eq('is_primary', true)
          .maybeSingle();

      if (assignment != null && assignment['trucks'] != null) {
        truckType = assignment['trucks']['truck_type'] ?? 'غير محدد';
      }

      await _loadAvailableOrders();

      _notificationsSub = supabase
          .from('notified_drivers')
          .stream(primaryKey: ['id'])
          .eq('driver_id', driver!['id'])
          .listen((_) {
        if (mounted) _loadAvailableOrders(refreshOnly: true);
      });

      _startLocationUpdates();
    } catch (e) {
      _showSnackBar('خطأ في جلب البيانات', Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      if (isAvailable && driver != null) _updateDriverLocation();
    });
    if (isAvailable) _updateDriverLocation();
  }

  Future<void> _updateDriverLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        String? city = placemarks.isNotEmpty ? placemarks[0].locality : null;

        await supabase.from('drivers').update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          if (city != null) 'current_city': city,
        }).eq('id', driver!['id']);

        if (mounted && city != null) setState(() => currentCity = city);
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _loadAvailableOrders({bool refreshOnly = false}) async {
    if (driver == null) return;
    if (!refreshOnly) setState(() => isLoading = true);

    try {
      final response = await supabase.rpc('get_driver_orders', params: {
        'p_driver_id': driver!['id'],
        'p_driver_lat': driver!['latitude'] ?? 0.0,
        'p_driver_lng': driver!['longitude'] ?? 0.0,
      });

      if (mounted) {
        setState(() {
          availableOrders = List<Map<String, dynamic>>.from(response).map((o) {
            double km = (o['distance_km'] as num?)?.toDouble() ?? 0.0;
            o['display_dist'] = km < 1 ? 'قريب جداً' : '${km.toStringAsFixed(1)} كم';
            return o;
          }).toList();
        });
      }
    } finally {
      if (mounted && !refreshOnly) setState(() => isLoading = false);
    }
  }

  Future<void> _submitOffer(Map<String, dynamic> order) async {
    final priceController = TextEditingController();
    final double? price = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          'تقديم عرض سعر',
          style: TextStyle(color: Color(0xFF1E4D2B), fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'من: ${order['from_location']}\nإلى: ${order['to_location']}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(color: Colors.black, fontSize: 26, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0.00',
                filled: true,
                fillColor: Colors.grey.shade100,
                suffixText: 'ريال',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.red))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(priceController.text)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71)),
            child: const Text('إرسال العرض', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (price != null && price > 0) {
      try {
        await supabase.from('order_offers').insert({
          'order_id': order['order_id'],
          'driver_id': driver!['id'],
          'offered_price': price,
          'status': 'pending',
        });
        _showSnackBar('تم إرسال عرضك بنجاح بـ $price ريال', Colors.green);
        _loadAvailableOrders(refreshOnly: true);
      } catch (e) {
        _showSnackBar('خطأ في إرسال العرض', Colors.red);
      }
    }
  }

  void _showSnackBar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m, textAlign: TextAlign.right), backgroundColor: c),
    );
  }

  Future<void> _openMapForOrder(Map<String, dynamic> order) async {
    final String fromLocation = order['from_location'] ?? 'مكة';
    final Uri googleMapsUrl;

    if (order['from_lat'] != null && order['from_lng'] != null) {
      final double lat = (order['from_lat'] as num).toDouble();
      final double lng = (order['from_lng'] as num).toDouble();
      googleMapsUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    } else {
      googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(fromLocation)}');
    }

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) _showSnackBar('لا يمكن فتح الخريطة', Colors.red);
    }
  }

  /// دالة تسجيل الخروج
  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // أو prefs.remove('isLoggedIn'); prefs.remove('userType'); prefs.remove('userPhone');

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/userType');
      _showSnackBar('تم تسجيل الخروج بنجاح', Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;
    final double horizontalPadding = isTablet ? size.width * 0.15 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('داشبورد السائق'),
        backgroundColor: const Color(0xFF1E4D2B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: _signOut,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E4D2B), Color(0xFF0D3B1E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isTablet, horizontalPadding),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'الطلبات المتاحة لك',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _loadAvailableOrders(refreshOnly: true),
                  color: const Color(0xFF2ECC71),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _buildOrdersList(isTablet, horizontalPadding),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet, double padding) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً، ${driver?['name'] ?? 'سائقنا'}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 26 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      currentCity,
                      style: TextStyle(color: Colors.white70, fontSize: isTablet ? 16 : 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildStatusSwitch(),
        ],
      ),
    );
  }

  Widget _buildStatusSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Text(isAvailable ? 'متصل' : 'متوقف', style: const TextStyle(color: Colors.white, fontSize: 12)),
          isSwitchLoading
              ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          )
              : Switch(
            value: isAvailable,
            activeColor: const Color(0xFF2ECC71),
            onChanged: (v) async {
              setState(() => isSwitchLoading = true);
              await supabase.from('drivers').update({'is_available': v ? 'online' : 'offline'}).eq('id', driver!['id']);
              setState(() {
                isAvailable = v;
                isSwitchLoading = false;
              });
              if (v) _updateDriverLocation();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(bool isTablet, double padding) {
    if (availableOrders.isEmpty) {
      return const Center(child: Text('لا توجد طلبات حالياً', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: padding),
      itemCount: availableOrders.length,
      itemBuilder: (context, index) {
        final order = availableOrders[index];
        final bool hasOffered = order['has_driver_offer'] == true;

        return InkWell(
          onTap: () => _openMapForOrder(order),
          borderRadius: BorderRadius.circular(15),
          child: Card(
            color: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${order['from_location']} ➔ ${order['to_location']}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                      ),
                      if (order['display_dist'] != null)
                        Text(
                          order['display_dist'],
                          style: const TextStyle(color: Colors.yellowAccent, fontSize: 13),
                        ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 25),
                  Text('نوع الشاحنة: ${order['truck_type']}', style: const TextStyle(color: Colors.white70)),
                  Text('الحمولة: ${order['load_details'] ?? 'غير محدد'}', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: hasOffered ? null : () => _submitOffer(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasOffered ? Colors.white24 : const Color(0xFF2ECC71),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.zero,
                      ),
                      child: Center(
                        child: Text(
                          hasOffered ? 'تم تقديم عرضك' : 'تقديم عرض سعر',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, height: 1.0, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}