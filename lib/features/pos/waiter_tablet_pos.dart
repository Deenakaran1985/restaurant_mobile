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
  String activeWaiterName = "Captain Rahul";

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
              Expanded(child: Text('Select Table Workspace & Captain Assignment', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19))),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.65,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
                childAspectRatio: 1.1,
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
                      content: Text('🍽️ Switched terminal to ${tbl.tableName} (Responsible: ${tbl.responsibleWaiter})', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.table_restaurant, color: statusColor, size: 28),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                              child: Text('Cap: ${tbl.capacity}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(tbl.tableName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('🧑‍🍳 ${tbl.responsibleWaiter}', style: const TextStyle(color: AppTheme.warningAmber, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
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

  // ORDER INTERCHANGE & TABLE TRANSFER MODAL (Mistaken Booking Fixes)
  void _showOrderInterchangeModal() {
    final currentTbl = _workflowService.getTable(selectedTable);
    if (currentTbl.accumulatedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppTheme.warningAmber,
        content: Text('⚠️ No active accumulated bill on Table T-$selectedTable to transfer or interchange!'),
      ));
      return;
    }

    int destTableNumber = _workflowService.tables.firstWhere((t) => t.tableNumber != selectedTable).tableNumber;
    String reasonText = "Mistaken table selected during initial order entry";
    int? selectedItemIndex; // null = entire bill

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final destTbl = _workflowService.getTable(destTableNumber);
          final bool isSameWaiter = destTbl.responsibleWaiter == currentTbl.responsibleWaiter || destTbl.responsibleWaiter == 'Unassigned' || currentTbl.responsibleWaiter == 'Captain Rahul';

          return AlertDialog(
            backgroundColor: AppTheme.darkCardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppTheme.warningAmber, width: 2)),
            title: Row(
              children: [
                const Icon(Icons.swap_horizontal_circle, color: AppTheme.warningAmber, size: 28),
                const SizedBox(width: 10),
                Expanded(child: Text('Interchange & Transfer Mistaken Order', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.infoAzure.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.infoAzure)),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: AppTheme.infoAzure, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Operational Transfer Rights & Parallel Sync', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  isSameWaiter
                                    ? '✅ AUTHORIZATION VERIFIED: $activeWaiterName has rights to handle both Table T-$selectedTable and Table T-$destTableNumber. No manager PIN required. Web & Mobile apps sync in parallel!'
                                    : '🔐 MANAGER OVERRIDE ACTIVE: Transferring order between different captain tables. Audit record maintained.',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From Source Table:', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                                child: Text('Table T-$selectedTable (${currentTbl.responsibleWaiter})', style: GoogleFonts.outfit(color: AppTheme.warningAmber, fontWeight: FontWeight.w800, fontSize: 15)),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          child: Icon(Icons.arrow_forward_ios, color: AppTheme.primaryEmerald, size: 20),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('To Destination Table:', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<int>(
                                dropdownColor: const Color(0xFF141A28),
                                value: destTableNumber,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.08),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: _workflowService.tables.where((t) => t.tableNumber != selectedTable).map((t) {
                                  return DropdownMenuItem<int>(
                                    value: t.tableNumber,
                                    child: Text('Table T-${t.tableNumber} [${t.status.name}]', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (val) => setModalState(() => destTableNumber = val!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    Text('Select Scope of Order Transfer:', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    RadioListTile<int?>(
                      title: Text('Interchange Entire Accumulated Table Bill (${currentTbl.accumulatedItems.length} Dishes • ₹${currentTbl.totalAmount.toStringAsFixed(0)})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      value: null,
                      groupValue: selectedItemIndex,
                      activeColor: AppTheme.primaryEmerald,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setModalState(() => selectedItemIndex = val),
                    ),
                    const Divider(color: Colors.white24),
                    Text('Or Transfer Only Specific Mistaken Dish Item:', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    for (int i = 0; i < currentTbl.accumulatedItems.length; i++)
                      RadioListTile<int?>(
                        title: Text('${currentTbl.accumulatedItems[i]['qty']}x ${currentTbl.accumulatedItems[i]['name']} (₹${currentTbl.accumulatedItems[i]['price']})', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        value: i,
                        groupValue: selectedItemIndex,
                        activeColor: AppTheme.warningAmber,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setModalState(() => selectedItemIndex = val),
                      ),

                    const SizedBox(height: 16),
                    Text('Justification / Audit Trail Reason:', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF141A28),
                      value: reasonText,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: [
                        "Mistaken table selected during initial order entry",
                        "Waiter interchanging order between assigned multi-tables",
                        "Guest group relocated seating across dining zones",
                        "Manager override table bill consolidation",
                      ].map((r) => DropdownMenuItem<String>(value: r, child: Text(r, style: const TextStyle(color: Colors.white, fontSize: 13)))).toList(),
                      onChanged: (val) => setModalState(() => reasonText = val!),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('CANCEL', style: GoogleFonts.outfit(color: AppTheme.slateGray, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningAmber, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                icon: const Icon(Icons.check_circle, size: 20),
                label: Text('EXECUTE TRANSFER & LOG AUDIT', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14)),
                onPressed: () {
                  final resultDesc = _workflowService.transferOrInterchangeOrder(
                    fromTableNum: selectedTable,
                    toTableNum: destTableNumber,
                    operatorRole: '$activeWaiterName (Table Owner Rights)',
                    reason: reasonText,
                    specificItemIndex: selectedItemIndex,
                  );
                  Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: AppTheme.primaryEmerald,
                      content: Text('🔄 $resultDesc! Audit log maintained & Web App synced in parallel.', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                      duration: const Duration(seconds: 5),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
              )
            ],
          );
        },
      ),
    );
  }

  // AUDIT HISTORY & TABLE OWNERSHIP LOGS MODAL
  void _showAuditHistoryModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppTheme.primaryEmerald, width: 2)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_edu, color: AppTheme.primaryEmerald, size: 28),
                  const SizedBox(width: 10),
                  Text('Table Transfer & Ownership Audit Trail', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primaryEmerald.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryEmerald)),
                child: const Text('Parallel Web Sync Active', style: TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 11)),
              )
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.6,
            child: _workflowService.auditLogs.isEmpty ? Center(
              child: Text('No table transfers or interchange audit events recorded yet today.', style: TextStyle(color: AppTheme.slateGray, fontSize: 15)),
            ) : ListView.builder(
              itemCount: _workflowService.auditLogs.length,
              itemBuilder: (context, i) {
                final log = _workflowService.auditLogs[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_user, color: AppTheme.infoAzure, size: 18),
                              const SizedBox(width: 8),
                              Text(log['operator']!, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.warningAmber.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(log['time']!, style: const TextStyle(color: AppTheme.warningAmber, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(log['action']!, style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('⚠️ Reason: ${log['reason']}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
                          Text('📡 ${log['sync_status']}', style: const TextStyle(color: AppTheme.infoAzure, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CLOSE AUDIT LOG', style: GoogleFonts.outfit(color: AppTheme.slateGray, fontWeight: FontWeight.bold)),
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
        waiterName: activeWaiterName,
      );
      
      setState(() {
        isLoading = false;
        cart.clear();
      });
      if (onComplete != null) onComplete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔥 [$smaId] Fired to Kitchen KDS! Order accumulated onto Table T-$selectedTable ($activeWaiterName). Parallel sync sent to Web App.', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
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
      padding: inBottomSheet ? const EdgeInsets.symmetric(vertical: 8) : const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!inBottomSheet) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Table T-$selectedTable Order Hub', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: 19, fontWeight: FontWeight.bold)),
                    Text('🧑‍🍳 Responsible: ${table.responsibleWaiter}', style: const TextStyle(color: AppTheme.warningAmber, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history_edu, color: AppTheme.infoAzure, size: 22),
                      tooltip: 'View Audit & Interchange Logs',
                      onPressed: _showAuditHistoryModal,
                    ),
                    InkWell(
                      onTap: _showTableSelectorModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.infoAzure.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.infoAzure)),
                        child: Text('SWITCH', style: GoogleFonts.inter(color: AppTheme.infoAzure, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
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
                  Text('Ticket ${readyTickets.first.id} finished prep in kitchen.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
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

          // STAGE 4 & INTERCHANGE: ACCUMULATED TABLE INVOICE
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${table.accumulatedItems.length} courses ordered so far.', style: const TextStyle(color: AppTheme.slateGray, fontSize: 12)),
                      InkWell(
                        onTap: _showOrderInterchangeModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.warningAmber.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.warningAmber)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.swap_horiz, color: AppTheme.warningAmber, size: 14),
                              const SizedBox(width: 4),
                              Text('INTERCHANGE', style: GoogleFonts.outfit(color: AppTheme.warningAmber, fontWeight: FontWeight.w800, fontSize: 11)),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
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
                      height: 40,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.infoAzure, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: Text('CLOSE BILL & FIRE TO CASHIER', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13)),
                        onPressed: () {
                          _workflowService.closeTableAndFireToCashier(selectedTable);
                          if (onStateChanged != null) onStateChanged();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            backgroundColor: AppTheme.infoAzure,
                            content: Text('📨 Table $selectedTable Bill ($currencySymbol${table.totalAmount.toStringAsFixed(2)}) closed and fired to Cashier Terminal & Thermal Printer!', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                            duration: const Duration(seconds: 4),
                          ));
                        },
                      ),
                    )
                ],
              ),
            ),
          ],

          Text(cart.isEmpty ? 'New Round Cart (Empty)' : 'New Round Items (${cart.length}):', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),

          Expanded(
            child: cart.isEmpty ? Center(
              child: Text('Tap dishes from menu grid to punch a new order round for Table T-$selectedTable.', style: TextStyle(color: AppTheme.slateGray, fontSize: 13), textAlign: TextAlign.center),
            ) : ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, i) {
                final item = cart[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
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
                            if (item['note'].isNotEmpty) Text('Note: ${item['note']}', style: const TextStyle(color: AppTheme.warningAmber, fontSize: 11)),
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
              const Text('New KOT Total:', style: TextStyle(color: Colors.white70, fontSize: 15)),
              Text('$currencySymbol${newItemsTotal.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: 21, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald, 
                foregroundColor: Colors.black, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                disabledBackgroundColor: Colors.white12
              ),
              icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.send_rounded, size: 20),
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
    final tbl = _workflowService.getTable(selectedTable);

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
                    const Icon(Icons.sync, size: 14, color: AppTheme.primaryEmerald),
                    const SizedBox(width: 5),
                    const Text('Web & Mobile Parallel Sync', style: TextStyle(color: AppTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
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
                    Text(isMobile ? 'T-$selectedTable (${tbl.responsibleWaiter})' : 'Table T-$selectedTable (${tbl.responsibleWaiter})', style: const TextStyle(color: AppTheme.infoAzure, fontSize: 12, fontWeight: FontWeight.bold)),
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
            icon: const Icon(Icons.history, color: AppTheme.infoAzure),
            tooltip: 'Audit History Logs',
            onPressed: _showAuditHistoryModal,
          ),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.darkCardBg,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, -3))],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald, 
                    foregroundColor: Colors.black, 
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.shopping_cart_checkout, size: 22),
                  label: Text(
                    'TABLE T-$selectedTable CART (${cart.length} NEW) • $currencySymbol${tbl.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  onPressed: () => _showMobileCartModal(context),
                ),
              ),
              if (tbl.accumulatedItems.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: AppTheme.warningAmber.withOpacity(0.2), padding: const EdgeInsets.all(14)),
                  icon: const Icon(Icons.swap_horiz, color: AppTheme.warningAmber, size: 26),
                  tooltip: 'Interchange Order',
                  onPressed: _showOrderInterchangeModal,
                )
              ]
            ],
          ),
        ),
      ) : null,
    );
  }
}
