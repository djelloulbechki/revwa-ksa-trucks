import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

// ... imports remain the same
class HomeDashboard extends StatefulWidget {
  final String driverPhone;

  const HomeDashboard({super.key, required this.driverPhone});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? driver;
  String currentCity = 'غير محدد';
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

      isAvailable = driver!['is_available'] == 'online' || driver!['is_available'] == null;
      currentCity = driver!['current_city'] ?? 'غير محدد';

      final assignmentResponse = await supabase
          .from('driver_truck_assignments')
          .select('trucks(truck_type)')
          .eq('driver_id', driver!['id'])
          .eq('is_primary', true)
          .maybeSingle();

      if (assignmentResponse != null && assignmentResponse['trucks'] != null) {
        truckType = assignmentResponse['trucks']['truck_type'] ?? 'غير محدد';
      }

      await _loadAvailableOrders();

      _notificationsSub = supabase
          .from('notified_drivers')
          .stream(primaryKey: ['id'])
          .eq('driver_id', driver!['id'])
          .listen((_) async {
        if (mounted) _loadAvailableOrders(refreshOnly: true);
      });

      _startLocationUpdates();
    } catch (e) {
      print('Error loading driver data: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في جلب البيانات: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      if (isAvailable && driver != null) await _updateDriverLocation();
    });
    if (isAvailable) _updateDriverLocation();
  }

  Future<void> _updateDriverLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      String? newCity;

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark p = placemarks[0];
          newCity = p.locality ?? p.subLocality ?? p.subAdministrativeArea ?? p.administrativeArea;
        }
      } catch (_) {}

      Map<String, dynamic> updateData = {'latitude': position.latitude, 'longitude': position.longitude};
      if (newCity != null && newCity.isNotEmpty) updateData['current_city'] = newCity;

      await supabase.from('drivers').update(updateData).eq('id', driver!['id']);

      if (mounted) {
        if (newCity != null && newCity.isNotEmpty) currentCity = newCity;
        _loadAvailableOrders(refreshOnly: true); // أسرع: فقط تحديث القيم بدل إعادة تحميل كل شيء
      }
    } catch (e) {
      print('Error updating location: $e');
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
        // تحديث أسرع: فقط تحديث العناصر الجديدة/الحالية
        availableOrders = List<Map<String, dynamic>>.from(response).map((order) {
          if (order['distance_km'] != null) {
            double km = order['distance_km'] as double;
            order['distance_km_display'] = km < 1 ? '< 1 كم' : '${km.toStringAsFixed(1)} كم';
          }
          return order;
        }).toList();
      }
    } catch (e) {
      print('Error loading available orders: $e');
      if (mounted && !refreshOnly) availableOrders = [];
    } finally {
      if (!refreshOnly && mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _submitOffer(Map<String, dynamic> order) async {
    final orderId = order['order_id'] as String;
    final controller = TextEditingController();

    final double? selectedPrice = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('قدم عرضك', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('من: ${order['from_location']} → ${order['to_location']}'),
              Text('نوع الشاحنة: ${order['truck_type']}'),
              if (order['min_manufacturing_year'] != null)
                Text('أدنى موديل: ${order['min_manufacturing_year']}'),
              if (order['load_details'] != null) Text('تفاصيل: ${order['load_details']}'),
              if (order['distance_km_display'] != null)
                Text('المسافة الحالية: ${order['distance_km_display']}', style: const TextStyle(color: Colors.yellowAccent)),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'السعر بالريال',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(controller.text);
              if (price != null && price > 0) Navigator.pop(context, price);
            },
            child: const Text('تقديم العرض'),
          ),
        ],
      ),
    );

    if (selectedPrice == null || selectedPrice <= 0) return;

    // تحديث محلي أسرع
    setState(() {
      order['has_driver_offer'] = true;
      order['offered_price'] = selectedPrice;
      order['offer_status'] = 'pending';
    });

    try {
      await supabase.from('order_offers').insert({
        'order_id': orderId,
        'driver_id': driver!['id'],
        'offered_price': selectedPrice,
        'status': 'pending',
      });

      await http.post(
        Uri.parse('https://revwa.cloud/webhook/new-offer-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': orderId, 'driver_id': driver!['id'], 'offered_price': selectedPrice}),
      );

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تقديم عرضك بـ $selectedPrice ريال بنجاح!')),
      );
    } catch (e) {
      print('Error submitting offer: $e');
    }
  }

  Future<void> _openMap(Map<String, dynamic> order) async {
    if (driver?['latitude'] == null || order['from_latitude'] == null) return;

    final url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=${driver!['latitude']},${driver!['longitude']}'
        '&destination=${order['from_latitude']},${order['from_longitude']}'
        '&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final double padding = size.width * 0.05;

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
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(padding),
                child: isPortrait
                    ? Column(children: _headerChildren())
                    : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: _headerChildren()),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'الطلبات المتاحة لك',
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
                    : availableOrders.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text('لا توجد طلبات حاليًا', style: TextStyle(fontSize: 18, color: Colors.white70)),
                      const SizedBox(height: 8),
                      const Text('اسحب لأسفل للتحديث', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: _loadAvailableOrders,
                  color: const Color(0xFF2ECC71),
                  child: ListView.builder(
                    padding: EdgeInsets.all(padding),
                    itemCount: availableOrders.length,
                    itemBuilder: (context, index) {
                      final order = availableOrders[index];
                      final offerStatus = order['offer_status'] as String?;
                      final hasOffered = order['has_driver_offer'] == true;
                      final isOfferAccepted = offerStatus == 'accepted' || offerStatus == 'assigned';

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Card(
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          color: isOfferAccepted ? const Color(0xFF2ECC71).withOpacity(0.3) : Colors.white.withOpacity(0.1),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(20),
                            onTap: () => _openMap(order),
                            title: Text('${order['from_location']} → ${order['to_location']}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isOfferAccepted)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: Text('🎉 تم قبول عرضك من العميل!', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 17)),
                                  ),
                                Text('نوع الشاحنة: ${order['truck_type']}', style: TextStyle(color: Colors.white70)),
                                if (order['min_manufacturing_year'] != null)
                                  Text('أدنى موديل: ${order['min_manufacturing_year']}', style: const TextStyle(color: Colors.orangeAccent)),
                                if (order['load_details'] != null && order['load_details'].toString().isNotEmpty)
                                  Text('التفاصيل: ${order['load_details']}', style: const TextStyle(color: Colors.white60)),
                                Text('العدد المطلوب: ${order['required_trucks_count'] ?? 1}', style: const TextStyle(color: Colors.white60)),
                                if (order['distance_km_display'] != null)
                                  Text('المسافة الحالية: ${order['distance_km_display']}', style: const TextStyle(color: Colors.yellowAccent, fontSize: 16)),
                                if (isOfferAccepted) ...[
                                  const SizedBox(height: 12),
                                  const Text('معلومات العميل:', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
                                  Text('الاسم: ${order['client_name'] ?? 'غير متوفر'}', style: const TextStyle(color: Colors.cyan)),
                                  Text('رقم الجوال: ${order['client_phone'] ?? 'غير متوفر'}', style: const TextStyle(color: Colors.cyan)),
                                ],
                                if (!isOfferAccepted)
                                  const Text('اضغط على الكارد لفتح المسار على الخريطة', style: TextStyle(color: Colors.cyanAccent, fontStyle: FontStyle.italic)),
                              ],
                            ),
                            trailing: isOfferAccepted
                                ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.greenAccent, size: 50),
                                Text('مقبول', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                              ],
                            )
                                : ElevatedButton.icon(
                              onPressed: hasOffered ? null : () => _submitOffer(order),
                              icon: hasOffered ? const Icon(Icons.check) : const Icon(Icons.send),
                              label: Text(hasOffered ? 'تم التقديم' : 'قدم عرض'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasOffered ? Colors.grey : const Color(0xFF2ECC71),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _headerChildren() {
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مرحبا، ${driver?['name'] ?? 'سائق'}!',
              style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.location_on, color: Colors.white70, size: 20), const SizedBox(width: 4), Text(currentCity, style: const TextStyle(color: Colors.white70, fontSize: 16))]),
          Row(children: [const Icon(Icons.local_shipping, color: Colors.white70, size: 20), const SizedBox(width: 4), Text(truckType, style: const TextStyle(color: Colors.white70, fontSize: 16))]),
        ],
      ),
      Column(
        children: [
          const Text('متاح للعمل', style: TextStyle(color: Colors.white70)),
          isSwitchLoading
              ? const CircularProgressIndicator(color: Color(0xFF2ECC71))
              : Switch(
            value: isAvailable,
            activeColor: const Color(0xFF2ECC71),
            onChanged: (value) async {
              setState(() => isSwitchLoading = true);
              try {
                await supabase.from('drivers').update({'is_available': value ? 'online' : 'offline'}).eq('id', driver!['id']);
                setState(() => isAvailable = value);
                if (value) _updateDriverLocation();
              } catch (e) {
                print('Error updating availability: $e');
              } finally {
                setState(() => isSwitchLoading = false);
              }
            },
          ),
        ],
      ),
    ];
  }
}
