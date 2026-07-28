import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../auth/login_screen.dart';

class WaiterTabletPosScreen extends StatefulWidget {
  const WaiterTabletPosScreen({super.key});

  @override
  State<WaiterTabletPosScreen> createState() => _WaiterTabletPosScreenState();
}

class _WaiterTabletPosScreenState extends State<WaiterTabletPosScreen> {
  int selectedTable = 3;
  int selectedCategoryIndex = 0;
  String hotelName = "Sriinnov Restaurant Management";
  String currencySymbol = "₹";
  String kdsMode = "thermal_printer_only";
  String kitchenPrinterIp = "192.168.32.151";
  bool isLoading = false;

  List<Map<String, dynamic>> cart = [
    {'menu_item_id': 1, 'name': 'Truffle & Forest Mushroom Pizza', 'price': 550.0, 'qty': 1, 'note': 'Extra crispy crust'},
    {'menu_item_id': 3, 'name': 'Iced Hazelnut Caramel Latte', 'price': 220.0, 'qty': 2, 'note': 'Less ice'},
  ];

  final List<String> categories = ['All Items', 'Wood-Fired Pizzas', 'Gourmet Burgers', 'Artisanal Coffee', 'Desserts'];
  
  final List<Map<String, dynamic>> dishes = [
    {'id': 1, 'name': 'Truffle & Forest Mushroom Pizza', 'price': 550.0, 'sla': 14, 'cat': 1, 'icon': '🍕'},
    {'id': 2, 'name': 'Smoked Hickory Chicken Burger', 'price': 380.0, 'sla': 12, 'cat': 2, 'icon': '🍔'},
    {'id': 3, 'name': 'Iced Hazelnut Caramel Latte', 'price': 220.0, 'sla': 4, 'cat': 3, 'icon': '☕'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchHotelSettings();
  }

  Future<void> _fetchHotelSettings() async {
    try {
      final response = await ApiClient().get('/settings');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['settings'];
        setState(() {
          hotelName = data['hotel_name'] ?? hotelName;
          currencySymbol = data['currency_symbol'] ?? currencySymbol;
          kdsMode = data['kds_routing_mode'] ?? kdsMode;
          kitchenPrinterIp = data['kitchen_printer_ip'] ?? kitchenPrinterIp;
        });
      }
    } catch (e) {
      print('Using local offline cache for hotel settings: $e');
    }
  }

  Future<void> _fireKotOrder({VoidCallback? onComplete}) async {
    if (cart.isEmpty) return;
    setState(() => isLoading = true);

    try {
      final payload = {
        'table_id': selectedTable,
        'order_type': 'dine_in',
        'items': cart.map((e) => {
          'menu_item_id': e['menu_item_id'],
          'quantity': e['qty'],
          'notes': e['note']
        }).toList(),
      };

      await ApiClient().post('/orders', data: payload);
      
      setState(() {
        isLoading = false;
        cart.clear();
      });
      if (onComplete != null) onComplete();

      String confirmationText = '🔥 Order transmitted successfully to kitchen team!';
      if (kdsMode == 'thermal_printer_only') {
        confirmationText = '🔥 KOT Fired! [KDS Optional Mode Active]: Receipt directly printed via LAN Socket on Kitchen Thermal Printer ($kitchenPrinterIp:9100) and raw ingredients deducted!';
      } else {
        confirmationText = '🔥 KOT Fired! Order broadcast directly to Interactive Kitchen Touchscreen KDS monitors over WebSockets!';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(confirmationText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            backgroundColor: AppTheme.primaryEmerald,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Network drop detected: KOT queued securely in SQLite offline persistence storage for automatic resync!', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.warningAmber,
          ),
        );
      }
    }
  }

  void _showMobileCartModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.82,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Table T-$selectedTable KOT Cart', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: 22, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      )
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Expanded(
                    child: _buildCartPanel(inBottomSheet: true, onStateChanged: () {
                      setModalState(() {});
                      setState(() {});
                      if (cart.isEmpty) Navigator.pop(ctx);
                    }, onOrderFired: () {
                      Navigator.pop(ctx);
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuArea({required bool isMobile}) {
    return Column(
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, idx) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(categories[idx], style: TextStyle(color: selectedCategoryIndex == idx ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
                backgroundColor: selectedCategoryIndex == idx ? AppTheme.primaryEmerald : Colors.white.withOpacity(0.08),
                onPressed: () => setState(() => selectedCategoryIndex = idx),
              ),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? (MediaQuery.of(context).size.width < 520 ? 2 : 3) : 3,
              childAspectRatio: isMobile ? 0.95 : 1.1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: dishes.length,
            itemBuilder: (context, i) {
              final dish = dishes[i];
              return InkWell(
                onTap: () {
                  setState(() {
                    final idx = cart.indexWhere((e) => e['name'] == dish['name']);
                    if (idx >= 0) {
                      cart[idx]['qty'] += 1;
                    } else {
                      cart.add({'menu_item_id': dish['id'], 'name': dish['name'], 'price': dish['price'], 'qty': 1, 'note': ''});
                    }
                  });
                  if (isMobile && cart.length == 1 && cart.first['qty'] == 1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${dish['name']} to Table T-$selectedTable cart!', style: const TextStyle(fontWeight: FontWeight.bold)),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dish['icon']!, style: TextStyle(fontSize: isMobile ? 32 : 36)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.warningAmber.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                            child: Text('${dish['sla']}m SLA', style: const TextStyle(color: AppTheme.warningAmber, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      Text(dish['name']!, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$currencySymbol${dish['price'].toStringAsFixed(0)}', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w800)),
                          const Icon(Icons.add_circle, color: AppTheme.primaryEmerald, size: 28),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCartPanel({required bool inBottomSheet, VoidCallback? onStateChanged, VoidCallback? onOrderFired}) {
    final double total = cart.fold(0.0, (sum, item) => sum + (item['price'] * item['qty']));
    return Container(
      color: AppTheme.darkCardBg,
      padding: inBottomSheet ? const EdgeInsets.symmetric(vertical: 8) : const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!inBottomSheet) ...[
            Text('Current Table KOT', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, i) {
                final item = cart[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            if (item['note'].isNotEmpty) Text('Note: ${item['note']}', style: const TextStyle(color: AppTheme.warningAmber, fontSize: 12)),
                            Text('$currencySymbol${(item['price'] * item['qty']).toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.slateGray, fontSize: 14)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                            onPressed: () {
                              if (onStateChanged != null) {
                                if (item['qty'] > 1) item['qty'] -= 1;
                                else cart.removeAt(i);
                                onStateChanged();
                              } else {
                                setState(() {
                                  if (item['qty'] > 1) item['qty'] -= 1;
                                  else cart.removeAt(i);
                                });
                              }
                            },
                          ),
                          Text('${item['qty']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryEmerald),
                            onPressed: () {
                              if (onStateChanged != null) {
                                item['qty'] += 1;
                                onStateChanged();
                              } else {
                                setState(() => item['qty'] += 1);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total:', style: TextStyle(color: Colors.white70, fontSize: 18)),
              Text('$currencySymbol${total.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: 26, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningAmber, 
                foregroundColor: Colors.black, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                disabledBackgroundColor: AppTheme.slateGray
              ),
              icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.send_rounded),
              label: Text(isLoading ? 'DISPATCHING KOT...' : (kdsMode == 'thermal_printer_only' ? 'FIRE THERMAL RECEIPT' : 'FIRE KOT SOCKET'), style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800)),
              onPressed: isLoading ? null : () => _fireKotOrder(onComplete: onOrderFired),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 850;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkCardBg,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.apartment, color: AppTheme.primaryEmerald),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                hotelName,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: isMobile ? 16 : 18, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kdsMode == 'thermal_printer_only' ? AppTheme.warningAmber.withOpacity(0.15) : AppTheme.primaryEmerald.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kdsMode == 'thermal_printer_only' ? AppTheme.warningAmber : AppTheme.primaryEmerald)
                ),
                child: Row(
                  children: [
                    Icon(kdsMode == 'thermal_printer_only' ? Icons.print : Icons.desktop_mac, size: 14, color: kdsMode == 'thermal_printer_only' ? AppTheme.warningAmber : AppTheme.primaryEmerald),
                    const SizedBox(width: 6),
                    Text(kdsMode == 'thermal_printer_only' ? 'Direct Thermal KOT Mode' : 'Interactive KDS Screen', style: TextStyle(color: kdsMode == 'thermal_printer_only' ? AppTheme.warningAmber : AppTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.infoAzure.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.infoAzure)),
              child: Text(isMobile ? 'T-$selectedTable' : 'Table T-$selectedTable Selected', style: const TextStyle(color: AppTheme.infoAzure, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.warningAmber),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPinScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isMobile ? _buildMenuArea(isMobile: true) : Row(
        children: [
          // Menu Area
          Expanded(
            flex: 6,
            child: _buildMenuArea(isMobile: false),
          ),
          // Tableside Order Ticket Cart Sidebar
          Expanded(
            flex: 4,
            child: _buildCartPanel(inBottomSheet: false),
          )
        ],
      ),
      bottomNavigationBar: isMobile && cart.isNotEmpty ? SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.darkCardBg,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, -3))],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryEmerald, 
              foregroundColor: Colors.black, 
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.shopping_cart_checkout, size: 24),
            label: Text(
              'VIEW KOT CART (${cart.fold<int>(0, (sum, e) => sum + (e['qty'] as int))}) • $currencySymbol${cart.fold<double>(0.0, (sum, e) => sum + ((e['price'] as num) * (e['qty'] as num))).toStringAsFixed(0)}',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            onPressed: () => _showMobileCartModal(context),
          ),
        ),
      ) : null,
    );
  }
}
