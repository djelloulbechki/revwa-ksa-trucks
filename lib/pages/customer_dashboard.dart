import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final Map<String, List<Map<String, dynamic>>> orderOffers = {};

  bool isLoading = true;
  String errorMessage = '';

  RealtimeChannel? ordersChannel;
  RealtimeChannel? offersChannel;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    ordersChannel?.unsubscribe();
    offersChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      clientId = await _getClientId();
      await _loadOrdersWithOffers();
      _listenOrders();
      _listenOffers();
    } catch (e) {
      errorMessage = 'خطأ في تحميل البيانات';
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<String> _getClientId() async {
    final res = await supabase
        .from('clients')
        .select('id')
        .eq('phone', widget.phone)
        .single();

    return res['id'];
  }

  /// 🔥 استعلام واحد فقط (Orders + Offers + Drivers)
  Future<void> _loadOrdersWithOffers() async {
    final res = await supabase
        .from('orders')
        .select('''
          *,
          order_offers(
            id,
            offered_price,
            status,
            drivers(id, name, rating, current_city)
          )
        ''')
        .eq('client_id', clientId)
        .order('created_at', ascending: false);

    orders = List<Map<String, dynamic>>.from(res);
    orderOffers.clear();

    for (final order in orders) {
      final offers = (order['order_offers'] ?? [])
          .where((o) => o['status'] == 'pending')
          .map<Map<String, dynamic>>((o) => Map<String, dynamic>.from(o))
          .toList();

      orderOffers[order['id']] = offers;
    }

    if (mounted) setState(() {});
  }

  /// Realtime Orders
  void _listenOrders() {
    ordersChannel = supabase
        .channel('orders-client-$clientId')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'orders',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'client_id',
        value: clientId,
      ),
      callback: (_) => _loadOrdersWithOffers(),
    )
        .subscribe();
  }

  /// Realtime Offers
  void _listenOffers() {
    offersChannel = supabase
        .channel('offers-client-$clientId')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'order_offers',
      callback: (payload) {
        final orderId =
            payload.newRecord?['order_id'] ?? payload.oldRecord?['order_id'];

        if (orderId != null &&
            orders.any((o) => o['id'] == orderId)) {
          _loadOrdersWithOffers();
        }
      },
    )
        .subscribe();
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

      if (res.statusCode != 200) throw Exception();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال اختيارك بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ، حاول مرة أخرى'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _ordersList() {
    if (orders.isEmpty) {
      return const Center(
        child: Text('لا توجد طلبات بعد',
            style: TextStyle(color: Colors.white70, fontSize: 18)),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, i) {
        final order = orders[i];
        final offers = orderOffers[order['id']] ?? [];

        return Card(
          color: Colors.white.withOpacity(0.1),
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'من ${order['from_location']} إلى ${order['to_location']}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text('نوع الشاحنة: ${order['Truck_type']}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                if (order['status'] == 'pending')
                  offers.isEmpty
                      ? const Text('في انتظار عروض...',
                      style: TextStyle(color: Colors.white70))
                      : ListView.builder(
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    itemCount: offers.length,
                    itemBuilder: (context, j) {
                      final offer = offers[j];
                      final driver = offer['drivers'];
                      final price =
                      (offer['offered_price'] as num).toDouble();

                      return Card(
                        color: Colors.white.withOpacity(0.15),
                        margin:
                        const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(driver['name'],
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                            FontWeight.bold)),
                                    Text('$price ريال',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18)),
                                    Text(
                                      'تقييم: ${driver['rating'] ?? 'غير متوفر'} ⭐ • مدينة: ${driver['current_city'] ?? 'غير محدد'}',
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => _acceptOffer(
                                  orderId: order['id'],
                                  offerId: offer['id'],
                                  driverId: driver['id'],
                                  price: price,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2ECC71),
                                    borderRadius:
                                    BorderRadius.circular(30),
                                  ),
                                  child: const Text('اختيار',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                          FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                else
                  const Text('تم تعيين سائق',
                      style: TextStyle(
                          color: Color(0xFF2ECC71),
                          fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(body: Center(child: Text(errorMessage)));
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('مرحبًا بك',
                      style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('طلب جديد'),
                    onPressed: () async {
                      final created = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CustomerRequestPage(phone: widget.phone),
                        ),
                      );
                      if (created == true) {
                        await _loadOrdersWithOffers();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(child: _ordersList()),
            ],
          ),
        ),
      ),
    );
  }
}
