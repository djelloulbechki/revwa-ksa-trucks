import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'customer_request_page.dart';

class CustomerDashboard extends StatefulWidget {
  final String phone;
  const CustomerDashboard({super.key, required this.phone});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final supabase = Supabase.instance.client;
  late String clientId;
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String errorMessage = '';
  RealtimeChannel? offersChannel;
  int _limit = 20;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    offersChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      if (mounted) setState(() => isLoading = true);
      clientId = await _getClientId();
      await _loadOrders();
      // _listenOffers(); // لو عايز realtime، فعّلها
    } catch (e) {
      print('خطأ في _initData: $e');
      if (mounted) setState(() {
        errorMessage = 'خطأ في تحميل البيانات: $e';
        isLoading = false;
      });
    }
  }

  Future<String> _getClientId() async {
    final res = await supabase.from('clients').select('id').eq('phone', widget.phone).single();
    print('Client ID: ${res['id']}');
    return res['id'];
  }

  Future<void> _loadOrders({bool isRefresh = false}) async {
    if (isRefresh) _offset = 0;
    try {
      final res = await supabase.rpc('get_client_orders', params: {
        'p_client_id': clientId,
        'p_limit': _limit,
        'p_offset': _offset,
      });
      print('عدد الطلبات اللي رجعت من RPC: ${res.length}');
      if (mounted) {
        setState(() {
          if (isRefresh) {
            orders = List<Map<String, dynamic>>.from(res ?? []);
          } else {
            orders.addAll(List<Map<String, dynamic>>.from(res ?? []));
          }
          isLoading = false;
          errorMessage = '';
        });
      }
    } catch (e) {
      print('خطأ في تحميل الطلبات: $e');
      if (mounted) setState(() {
        errorMessage = 'فشل تحميل الطلبات: $e';
        isLoading = false;
      });
    }
  }

  void _listenOffers() {
    offersChannel = supabase.channel('offers-client-${widget.phone}').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'order_offers',
      callback: (_) {
        print('تغيير في العروض → إعادة تحميل');
        if (mounted) _loadOrders(isRefresh: true);
      },
    ).subscribe();
  }

  Future<void> _acceptOffer({
    required String orderId,
    required String offerId,
    required String driverId,
    required double price,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('https://revwa.cloud/webhook/offer-accepted-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'offer_id': offerId,
          'driver_id': driverId,
          'offered_price': price,
          'client_phone': widget.phone,
        }),
      );
      if (res.statusCode == 200) {
        _showSnackBar('تم اختيار السائق بنجاح', Colors.green);
        if (mounted) _loadOrders(isRefresh: true);
      } else {
        _showSnackBar('فشل في قبول العرض', Colors.red);
      }
    } catch (e) {
      _showSnackBar('خطأ في الاتصال: $e', Colors.red);
    }
  }

  void _showSnackBar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m, textAlign: TextAlign.right), backgroundColor: c),
    );
  }

  /// دالة تسجيل الخروج (نفس اللي في السائق)
  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userType');
    await prefs.remove('userPhone');
    await supabase.auth.signOut(); // خروج من Supabase كمان
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/userType');
      _showSnackBar('تم تسجيل الخروج بنجاح', Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;
    final double horizontalPadding = isTablet ? size.width * 0.15 : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي'),
        backgroundColor: const Color(0xFF1E4D2B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: _signOut, // ← الزر الجديد هنا
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
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
            children: [
              _buildHeader(horizontalPadding, isTablet),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _loadOrders(isRefresh: true),
                  color: const Color(0xFF2ECC71),
                  child: errorMessage.isNotEmpty
                      ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
                      : _buildOrdersList(horizontalPadding, isTablet),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double padding, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('طلباتي', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              Text('تابع عروضك الحالية', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 20),
            label: Text(isTablet ? 'إنشاء طلب جديد' : 'طلب جديد'),
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => CustomerRequestPage(phone: widget.phone)),
              );
              if (created == true && mounted) _loadOrders(isRefresh: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(double padding, bool isTablet) {
    if (orders.isEmpty) {
      return const Center(child: Text('لا توجد طلبات بعد', style: TextStyle(color: Colors.white54, fontSize: 16)));
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 10),
      physics: const ClampingScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, i) {
        final order = orders[i];
        final List allOffers = order['order_offers'] ?? [];
        final offers = allOffers.where((o) => o != null && o['status'] == 'pending').toList();
        return Card(
          color: Colors.white.withOpacity(0.08),
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.05))),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text('${order['from_location']} ➔ ${order['to_location']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text(
                order['status'] == 'pending' ? 'جاري استقبال العروض...' : 'تم التعيين',
                style: TextStyle(color: order['status'] == 'pending' ? Colors.orangeAccent : const Color(0xFF2ECC71), fontSize: 13),
              ),
              childrenPadding: const EdgeInsets.all(12),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white70,
              children: [
                if (order['status'] == 'pending')
                  offers.isEmpty
                      ? const Padding(padding: EdgeInsets.all(10), child: Text('لا توجد عروض حتى الآن', style: TextStyle(color: Colors.white38)))
                      : Column(children: offers.map((o) => _buildOfferItem(o, order['id'])).toList())
                else
                  const Padding(padding: EdgeInsets.all(10), child: Text('تم إغلاق الطلب وتعيين سائق', style: TextStyle(color: Colors.white70))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOfferItem(Map<String, dynamic> offer, String orderId) {
    final driver = offer['drivers'] ?? {};
    final price = (offer['offered_price'] as num).toDouble();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: const Color(0xFF2ECC71).withOpacity(0.2), child: const Icon(Icons.person, color: Color(0xFF2ECC71))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver['name'] ?? 'سائق ريڤوا', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('${driver['rating'] ?? '5.0'} ⭐ • ${driver['current_city'] ?? 'موقع غير محدد'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$price ريال', style: const TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _acceptOffer(orderId: orderId, offerId: offer['id'], driverId: driver['id'], price: price),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  minimumSize: const Size(80, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('اختيار', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}