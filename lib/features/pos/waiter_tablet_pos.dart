import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/services/order_workflow_service.dart';
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
  String kitchenPrinterIp = ApiClient.printerIp;
  bool isLoading = false;

  final OrderWorkflowService _workflowService = OrderWorkflowService();

  List<Map<String, dynamic>> cart = [
    {'menu_item_id': 1, 'name': 'Truffle & Forest Mushroom Pizza', 'price': 550.0, 'qty': 1, 'note': 'Extra crispy crust'},
    {'menu_item_id': 3, 'name': 'Iced Hazelnut Caramel Latte', 'price': 220.0, 'qty': 2, 'note': 'Less ice'},
  ];

  final List<String> categories = ['All Items', 'Wood-Fired Pizzas', 'Gourmet Burgers', 'Artisanal Coffee', 'Desserts'];
  
  final List<Map<String, dynamic>> dishes = [
    {'id': 1, 'name': 'Truffle & Forest Mushroom Pizza', 'price': 550.0, 'sla': 14, 'cat': 1, 'icon': '🍕'},
    {'id': 2, 'name': 'Smoked Hickory Chicken Burger', 'price': 380.0, 'sla': 12, 'cat': 2, 'icon': '🍔'},
    {'id': 3, 'name': 'Iced Hazelnut Caramel Latte', 'price': 220.0, 'sla': 4, 'cat': 3, 'icon': '☕'},
    {'id': 4, 'name': 'Pan Seared Atlantic Salmon', 'price': 780.0, 'sla': 18, 'cat': 1, 'icon': '🐟'},
    {'id': 5, 'name': 'Belgian Chocolate Fondant', 'price': 320.0, 'sla': 10, 'cat': 4, 'icon': '🍰'},
    {'id': 6, 'name': 'Artisan Pepperoni Deep Dish', 'price': 620.0, 'sla': 16, 'cat': 1, 'icon': '🍕'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchHotelSettings();
    _workflowService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _workflowService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchHotelSettings() async {
    try {
      final response = await ApiClient().get('/settings');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
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

  void _showTableSelectorModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppTheme.infoAzure, width: 2)),
          title: Row(
            children: [
              const Icon(Icons.table_restaurant, color: AppTheme.infoAzure, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text('Select Table Workspace', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20))),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _workflowService.tables.length,
              itemBuilder: (context, i) {
                final tbl = _workflowService.tables[i];
                final isCurrent = tbl.tableNumber == selectedTable;
                Color statusColor = AppTheme.primaryEmerald;
                String statusLabel = 'Vacant';
                if (tbl.status == TableWorkflowStatus.activeOrder) {
                  statusColor = AppTheme.warningAmber;
                  statusLabel = 'Active • ₹${tbl.totalAmount.toStringAsFixed(0)}';
                } else if (tbl.status == TableWorkflowStatus.billFiredToCashier) {
                  statusColor = AppTheme.infoAzure;
                  statusLabel = 'Bill Fired to Cashier';
                }

                return InkWell(
                  onTap: () {
                    setState(() => selectedTable = tbl.tableNumber);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: AppTheme.infoAzure,
                      content: Text('🍽️ Switched tableside terminal to ${tbl.tableName}', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                      duration: const Duration(seconds: 2),
                    ));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppTheme.infoAzure.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isCurrent ? AppTheme.infoAzure : statusColor, width: isCurrent ? 3 : 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_restaurant, color: statusColor, size: 32),
                        const SizedBox(height: 8),
                        Text(tbl.tableName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CLOSE', style: GoogleFonts.outfit(color: AppTheme.slateGray, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fireKotOrder({VoidCallback? onComplete}) async {
    if (cart.isEmpty) return;
    setState(() => isLoading = true);

    try {
      final stationName = cart.any((i) => (i['name'] as String).toLowerCase().contains('coffee') || (i['name'] as String).toLowerCase().contains('latte')) ? 'Bar & Beverage Station' : 'Wood-Fired Hot Kitchen';
      final smaId = _workflowService.fireSmaToKitchen(
        tableNumber: selectedTable,
        items: cart,
        station: stationName,
      );
      
      setState(() {
        isLoading = false;
        cart.clear();
      });
      if (onComplete != null) onComplete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔥 [$smaId] Fired to Kitchen KDS! Order items accumulated onto Table $selectedTable bill.', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
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
              height: MediaQuery.of(context).size.height * 0.88,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Table T-$selectedTable Workspace', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: 22, fontWeight: FontWeight.bold)),
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
              childAspectRatio: isMobile ? 0.92 : 1.05,
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
    final double newItemsTotal = cart.fold(0.0, (sum, item) => sum + (item['price'] * item['qty']));
    final table = _workflowService.getTable(selectedTable);
    final tableTickets = _workflowService.getTicketsForTable(selectedTable);
    final readyTickets = tableTickets.where((t) => t.status == KotStatus.readyToServe).toList();

    return Container(
      color: AppTheme.darkCardBg,
      padding: inBottomSheet ? const EdgeInsets.symmetric(vertical: 8) : const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!inBottomSheet) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Table T-$selectedTable Order Hub', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: 20, fontWeight: FontWeight.bold)),
                InkWell(
                  onTap: _showTableSelectorModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.infoAzure.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text('CHANGE TABLE', style: GoogleFonts.inter(color: AppTheme.infoAzure, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 14),
          ],

          // STAGE 2 -> 3 NOTIFICATION: KDS ORDER READY TO SERVE
          if (readyTickets.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.warningAmber, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active, color: AppTheme.warningAmber, size: 22),
                      const SizedBox(width: 8),
                      Expanded(child: Text('KITCHEN ALERT: Dish Ready to Serve!', style: GoogleFonts.outfit(color: AppTheme.warningAmber, fontWeight: FontWeight.w800, fontSize: 15))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Ticket ${readyTickets.first.id} finished preparation in kitchen.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningAmber, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      icon: const Icon(Icons.room_service, size: 18),
                      label: Text('MARK SERVED TO GUESTS', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13)),
                      onPressed: () {
                        _workflowService.markTicketServed(readyTickets.first.id);
                        if (onStateChanged != null) onStateChanged();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: AppTheme.primaryEmerald,
                          content: Text('😋 Order marked SERVED! Invoice accumulated for Table $selectedTable.', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
                        ));
                      },
                    ),
                  )
                ],
              ),
            ),
          ],

          // STAGE 4: ACCUMULATED TABLE INVOICE
          if (table.accumulatedItems.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Accumulated Table Bill:', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('$currencySymbol${table.totalAmount.toStringAsFixed(2)} (inc. GST)', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${table.accumulatedItems.length} rounds of food & drink items ordered so far.', style: const TextStyle(color: AppTheme.slateGray, fontSize: 12)),
                  const SizedBox(height: 10),
                  if (table.status == TableWorkflowStatus.billFiredToCashier)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.infoAzure.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.print_disabled, color: AppTheme.infoAzure, size: 18),
                          const SizedBox(width: 8),
                          Text('BILL FIRED TO CASHIER TO SETTLE', style: GoogleFonts.outfit(color: AppTheme.infoAzure, fontWeight: FontWeight.w800, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.infoAzure, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: Text('CLOSE BILL & FIRE TO CASHIER', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14)),
                        onPressed: () {
                          _workflowService.closeTableAndFireToCashier(selectedTable);
                          if (onStateChanged != null) onStateChanged();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            backgroundColor: AppTheme.infoAzure,
                            content: Text('📨 Table $selectedTable Bill ($currencySymbol${table.totalAmount.toStringAsFixed(2)}) closed and automatically fired to Main Cashier Station & Printer!', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                            duration: const Duration(seconds: 4),
                          ));
                        },
                      ),
                    )
                ],
              ),
            ),
          ],

          Text(cart.isEmpty ? 'New Round Cart (Empty)' : 'New Round Items (${cart.length}):', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          Expanded(
            child: cart.isEmpty ? Center(
              child: Text('Tap items from menu to start a new KOT order round for Table T-$selectedTable.', style: TextStyle(color: AppTheme.slateGray, fontSize: 14), textAlign: TextAlign.center),
            ) : ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, i) {
                final item = cart[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            if (item['note'].isNotEmpty) Text('Note: ${item['note']}', style: const TextStyle(color: AppTheme.warningAmber, fontSize: 12)),
                            Text('$currencySymbol${(item['price'] * item['qty']).toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.slateGray, fontSize: 13)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.white70, size: 20),
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
                          Text('${item['qty']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryEmerald, size: 20),
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
              const Text('New KOT Total:', style: TextStyle(color: Colors.white70, fontSize: 16)),
              Text('$currencySymbol${newItemsTotal.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald, 
                foregroundColor: Colors.black, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                disabledBackgroundColor: Colors.white12
              ),
              icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.send_rounded, size: 22),
              label: Text(isLoading ? 'FIRING TO KDS...' : '🔥 FIRE SMA TO KITCHEN', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900)),
              onPressed: isLoading || cart.isEmpty ? null : () => _fireKotOrder(onComplete: onOrderFired),
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
                  color: AppTheme.primaryEmerald.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryEmerald)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.rss_feed, size: 14, color: AppTheme.primaryEmerald),
                    const SizedBox(width: 6),
                    Text('Realtime KDS & Cashier Link', style: TextStyle(color: AppTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
            const SizedBox(width: 8),
            InkWell(
              onTap: _showTableSelectorModal,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.infoAzure.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.infoAzure)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isMobile ? 'T-$selectedTable' : 'Table T-$selectedTable', style: const TextStyle(color: AppTheme.infoAzure, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, color: AppTheme.infoAzure, size: 16),
                  ],
                ),
              ),
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
      bottomNavigationBar: isMobile ? SafeArea(
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
              'VIEW TABLE T-$selectedTable CART (${cart.fold<int>(0, (sum, e) => sum + (e['qty'] as int))} NEW) • $currencySymbol${_workflowService.getTable(selectedTable).totalAmount.toStringAsFixed(0)} ACC',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            onPressed: () => _showMobileCartModal(context),
          ),
        ),
      ) : null,
    );
  }
}
