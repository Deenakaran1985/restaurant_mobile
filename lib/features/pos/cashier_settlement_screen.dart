import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/services/order_workflow_service.dart';
import '../auth/login_screen.dart';

class CashierSettlementScreen extends StatefulWidget {
  const CashierSettlementScreen({super.key});

  @override
  State<CashierSettlementScreen> createState() => _CashierSettlementScreenState();
}

class _CashierSettlementScreenState extends State<CashierSettlementScreen> {
  final OrderWorkflowService _workflowService = OrderWorkflowService();
  int? selectedTableNumber;
  String selectedTenderMode = 'UPI / QR Instant (PhonePe / GPay)';
  bool isProcessing = false;

  final List<Map<String, String>> tenderModes = [
    {'mode': 'UPI / QR Instant (PhonePe / GPay)', 'icon': '📱', 'desc': 'Scan customer QR or send payment request link'},
    {'mode': 'Cash Collection', 'icon': '💵', 'desc': 'Physical currency & counter cash drawer opening'},
    {'mode': 'Credit / Debit EMV Card', 'icon': '💳', 'desc': 'Swipe / NFC Contactless on payment POS EDC terminal'},
    {'mode': 'Hotel Room Charge / Folio Post', 'icon': '🏨', 'desc': 'Directly debit room guest account balance via PMS link'},
    {'mode': 'Split Tender Split Mode', 'icon': '✂️', 'desc': 'Divide payment between Cash, Card, and UPI digital tokens'},
  ];

  @override
  void initState() {
    super.initState();
    _workflowService.addListener(_onServiceUpdate);
    _selectInitialTable();
  }

  @override
  void dispose() {
    _workflowService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      _selectInitialTable();
      setState(() {});
    }
  }

  void _selectInitialTable() {
    final pending = _workflowService.cashierPendingBills;
    final allOccupied = _workflowService.tables.where((t) => t.accumulatedItems.isNotEmpty && t.status != TableWorkflowStatus.paid).toList();
    
    if (selectedTableNumber == null || (_workflowService.getTable(selectedTableNumber!).accumulatedItems.isEmpty && allOccupied.isNotEmpty)) {
      if (pending.isNotEmpty) {
        selectedTableNumber = pending.first.tableNumber;
      } else if (allOccupied.isNotEmpty) {
        selectedTableNumber = allOccupied.first.tableNumber;
      }
    }
  }

  Future<void> _settleAndPrintReceipt(TableSession table) async {
    setState(() => isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate LAN receipt printer transmission

    _workflowService.settleTableBill(
      tableNumber: table.tableNumber,
      paymentMode: selectedTenderMode,
    );

    setState(() => isProcessing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Table ${table.tableName} Settle & Print Success! ₹${table.totalAmount.toStringAsFixed(2)} collected via $selectedTenderMode. Fiscal receipt fired to thermal printer (${ApiClient.printerIp}:9100). Table reset to Vacant!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
          backgroundColor: AppTheme.primaryEmerald,
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildQueuePanel(bool isMobile, List<TableSession> billRequestedTables, List<TableSession> activeTables) {
    return Container(
      color: const Color(0xFF0B0F19),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.point_of_sale, color: AppTheme.infoAzure, size: 28),
              const SizedBox(width: 10),
              Expanded(child: Text('Cashier Settlement Queue', style: GoogleFonts.outfit(color: Colors.white, fontSize: isMobile ? 20 : 22, fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 6),
          Text('Bills closed by waiters are automatically transferred here for multi-mode payment collection.', style: TextStyle(color: AppTheme.slateGray, fontSize: isMobile ? 13 : 14)),
          const SizedBox(height: 20),
          if (billRequestedTables.isEmpty && activeTables.isEmpty) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user_outlined, color: AppTheme.primaryEmerald, size: 64),
                    const SizedBox(height: 16),
                    Text('All Dining Bills Settled!', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Waiting for Waiters to close tables and fire new invoices...', style: TextStyle(color: AppTheme.slateGray, fontSize: 14), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ListView(
                children: [
                  if (billRequestedTables.isNotEmpty) ...[
                    Text('🚨 FIRED BY WAITER (AWAITING PAYMENT)', style: GoogleFonts.outfit(color: AppTheme.infoAzure, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    for (var tbl in billRequestedTables) _buildTableCard(tbl, isFired: true),
                    const SizedBox(height: 16),
                  ],
                  if (activeTables.isNotEmpty) ...[
                    Text('🍽️ ACTIVE TABLE RUNNING BILLS', style: GoogleFonts.outfit(color: AppTheme.warningAmber, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    for (var tbl in activeTables) _buildTableCard(tbl, isFired: false),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableCard(TableSession tbl, {required bool isFired}) {
    final isSelected = tbl.tableNumber == selectedTableNumber;
    return InkWell(
      onTap: () => setState(() => selectedTableNumber = tbl.tableNumber),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.infoAzure.withOpacity(0.2) : AppTheme.darkCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.infoAzure : (isFired ? AppTheme.infoAzure.withOpacity(0.5) : Colors.white12), width: isSelected ? 2.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isFired ? Icons.receipt_long : Icons.restaurant, color: isFired ? AppTheme.infoAzure : AppTheme.warningAmber, size: 20),
                    const SizedBox(width: 8),
                    Text(tbl.tableName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${tbl.zone} • ${tbl.capacity} Guests • ${tbl.accumulatedItems.length} Items', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${tbl.totalAmount.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: (isFired ? AppTheme.infoAzure : AppTheme.warningAmber).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(isFired ? 'READY TO PAY' : 'RUNNING', style: TextStyle(color: isFired ? AppTheme.infoAzure : AppTheme.warningAmber, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementHub(TableSession? table, bool isMobile) {
    if (table == null || table.accumulatedItems.isEmpty) {
      return Container(
        color: AppTheme.darkCardBg,
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text('Select a table from the settlement queue to view accumulated invoice & collect payment.', style: TextStyle(color: AppTheme.slateGray, fontSize: 16), textAlign: TextAlign.center),
        ),
      );
    }

    return Container(
      color: AppTheme.darkCardBg,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invoice Settlement Hub', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: isMobile ? 20 : 22, fontWeight: FontWeight.bold)),
                  Text(table.tableName, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.infoAzure.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.print, color: AppTheme.infoAzure, size: 16),
                    const SizedBox(width: 6),
                    Text('Printer: ${ApiClient.printerIp}', style: const TextStyle(color: AppTheme.infoAzure, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 28),
          
          // Itemized Breakdown Scroll
          Text('Accumulated Table Items & KOT History:', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: table.accumulatedItems.length,
              itemBuilder: (context, idx) {
                final item = table.accumulatedItems[idx];
                final price = (item['price'] as num).toDouble();
                final qty = (item['qty'] as num).toInt();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppTheme.primaryEmerald, borderRadius: BorderRadius.circular(6)),
                              child: Text('${qty}x', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))),
                          ],
                        ),
                      ),
                      Text('₹${(price * qty).toStringAsFixed(2)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(color: Colors.white24, height: 24),
          
          // Fiscal Totals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(color: Colors.white70, fontSize: 15)),
              Text('₹${table.subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('5% Dining GST Tax:', style: TextStyle(color: Colors.white70, fontSize: 15)),
              Text('₹${table.gstTax.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total to Collect:', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('₹${table.totalAmount.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: 28, fontWeight: FontWeight.w900)),
            ],
          ),

          const SizedBox(height: 18),
          Text('Select Tender / Payment Mode:', style: GoogleFonts.outfit(color: AppTheme.warningAmber, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          // Payment Modes Selector
          SizedBox(
            height: isMobile ? 130 : 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tenderModes.length,
              itemBuilder: (context, idx) {
                final m = tenderModes[idx];
                final isModeSelected = m['mode'] == selectedTenderMode;
                return InkWell(
                  onTap: () => setState(() => selectedTenderMode = m['mode']!),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: isMobile ? 140 : 160,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isModeSelected ? AppTheme.primaryEmerald.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isModeSelected ? AppTheme.primaryEmerald : Colors.white12, width: isModeSelected ? 2.5 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(m['icon']!, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(m['mode']!, style: GoogleFonts.outfit(color: isModeSelected ? AppTheme.primaryEmerald : Colors.white, fontWeight: FontWeight.w800, fontSize: 13), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(m['desc']!, style: const TextStyle(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              icon: isProcessing ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3)) : const Icon(Icons.print, size: 26),
              label: Text(
                isProcessing ? 'FIRING RECEIPT TO PRINTER...' : '🖨️ SETTLE INVOICE & PRINT THERMAL RECEIPT',
                style: GoogleFonts.outfit(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w900),
              ),
              onPressed: isProcessing ? null : () => _settleAndPrintReceipt(table),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final billRequestedTables = _workflowService.cashierPendingBills;
    final activeTables = _workflowService.tables.where((t) => t.accumulatedItems.isNotEmpty && t.status == TableWorkflowStatus.activeOrder).toList();
    
    TableSession? currentTable;
    if (selectedTableNumber != null) {
      currentTable = _workflowService.getTable(selectedTableNumber!);
      if (currentTable.accumulatedItems.isEmpty) currentTable = null;
    }
    if (currentTable == null && billRequestedTables.isNotEmpty) currentTable = billRequestedTables.first;
    if (currentTable == null && activeTables.isNotEmpty) currentTable = activeTables.first;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: AppTheme.darkCardBg,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: AppTheme.primaryEmerald),
            const SizedBox(width: 10),
            Flexible(
              child: Text('Main Cashier Terminal & Thermal Printing Hub', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: isMobile ? 16 : 19), overflow: TextOverflow.ellipsis),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.infoAzure.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.infoAzure)),
                child: Text('${billRequestedTables.length} Awaiting Cashier Settlement', style: const TextStyle(color: AppTheme.infoAzure, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.accentCrimson),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPinScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isMobile ? DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              indicatorColor: AppTheme.primaryEmerald,
              labelColor: AppTheme.primaryEmerald,
              unselectedLabelColor: Colors.white70,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
              tabs: [
                Tab(text: 'Pending Queue (${billRequestedTables.length + activeTables.length})', icon: const Icon(Icons.list_alt)),
                Tab(text: currentTable == null ? 'Checkout Station' : 'Settle ${currentTable.tableName}', icon: const Icon(Icons.point_of_sale)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildQueuePanel(true, billRequestedTables, activeTables),
                  _buildSettlementHub(currentTable, true),
                ],
              ),
            ),
          ],
        ),
      ) : Row(
        children: [
          Expanded(flex: 4, child: _buildQueuePanel(false, billRequestedTables, activeTables)),
          Expanded(flex: 6, child: _buildSettlementHub(currentTable, false)),
        ],
      ),
    );
  }
}
