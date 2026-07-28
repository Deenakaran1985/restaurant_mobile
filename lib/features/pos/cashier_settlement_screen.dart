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
                  Text('Cashier Table Audit & Interchange Log', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
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

  // CASHIER / MANAGER ORDER INTERCHANGE MODAL
  void _showOrderInterchangeModal(TableSession table) {
    int destTableNumber = _workflowService.tables.firstWhere((t) => t.tableNumber != table.tableNumber).tableNumber;
    String reasonText = "Manager / Cashier correcting mistaken table booking";
    int? selectedItemIndex; // null = entire bill

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            backgroundColor: AppTheme.darkCardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppTheme.warningAmber, width: 2)),
            title: Row(
              children: [
                const Icon(Icons.swap_horizontal_circle, color: AppTheme.warningAmber, size: 28),
                const SizedBox(width: 10),
                Expanded(child: Text('Cashier Order Interchange & Transfer', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
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
                      decoration: BoxDecoration(color: AppTheme.primaryEmerald.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryEmerald)),
                      child: Row(
                        children: [
                          const Icon(Icons.admin_panel_settings, color: AppTheme.primaryEmerald, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Universal Cashier & Manager Override Authorization', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                const Text('✅ AUTHORIZED: As Manager/Cashier, you have full administrative rights to transfer or interchange mistakenly booked orders between any dining tables. Web App synced in parallel.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                                child: Text('Table T-${table.tableNumber} (${table.responsibleWaiter})', style: GoogleFonts.outfit(color: AppTheme.warningAmber, fontWeight: FontWeight.w800, fontSize: 15)),
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
                                items: _workflowService.tables.where((t) => t.tableNumber != table.tableNumber).map((t) {
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
                      title: Text('Interchange Entire Accumulated Bill (${table.accumulatedItems.length} Dishes • ₹${table.totalAmount.toStringAsFixed(0)})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      value: null,
                      groupValue: selectedItemIndex,
                      activeColor: AppTheme.primaryEmerald,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setModalState(() => selectedItemIndex = val),
                    ),
                    const Divider(color: Colors.white24),
                    Text('Or Transfer Only Specific Mistaken Dish Item:', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    for (int i = 0; i < table.accumulatedItems.length; i++)
                      RadioListTile<int?>(
                        title: Text('${table.accumulatedItems[i]['qty']}x ${table.accumulatedItems[i]['name']} (₹${table.accumulatedItems[i]['price']})', style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
                        "Manager / Cashier correcting mistaken table booking",
                        "Guest group relocated seating across dining zones",
                        "Waiter reported interchanged table orders",
                        "Split or merge dining table invoices",
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
                    fromTableNum: table.tableNumber,
                    toTableNum: destTableNumber,
                    operatorRole: 'Main Cashier / Manager Override',
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

  Future<void> _settleAndPrintReceipt(TableSession table) async {
    setState(() => isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 600));

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
          Text('Bills closed by captains are transferred here. Manager/Cashier overrides active for order interchange.', style: TextStyle(color: AppTheme.slateGray, fontSize: isMobile ? 13 : 14)),
          const SizedBox(height: 18),
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
                    const SizedBox(height: 10),
                    for (var tbl in billRequestedTables) _buildTableCard(tbl, isFired: true),
                    const SizedBox(height: 16),
                  ],
                  if (activeTables.isNotEmpty) ...[
                    Text('🍽️ ACTIVE TABLE RUNNING BILLS', style: GoogleFonts.outfit(color: AppTheme.warningAmber, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.infoAzure.withOpacity(0.2) : AppTheme.darkCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.infoAzure : (isFired ? AppTheme.infoAzure.withOpacity(0.5) : Colors.white12), width: isSelected ? 2.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isFired ? Icons.receipt_long : Icons.restaurant, color: isFired ? AppTheme.infoAzure : AppTheme.warningAmber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tbl.tableName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('🧑‍🍳 Owner: ${tbl.responsibleWaiter}', style: const TextStyle(color: AppTheme.warningAmber, fontSize: 12, fontWeight: FontWeight.w700)),
                  Text('${tbl.zone} • ${tbl.capacity} Guests • ${tbl.accumulatedItems.length} Dishes', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
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
          child: Text('Select a table from the settlement queue to view invoice & collect multi-mode payment.', style: TextStyle(color: AppTheme.slateGray, fontSize: 16), textAlign: TextAlign.center),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invoice Settlement Hub', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: isMobile ? 20 : 22, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Text(table.tableName, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.warningAmber.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.warningAmber)),
                          child: Text('Responsible: ${table.responsibleWaiter}', style: const TextStyle(color: AppTheme.warningAmber, fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showOrderInterchangeModal(table),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.warningAmber.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.warningAmber)),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz, color: AppTheme.warningAmber, size: 16),
                      const SizedBox(width: 5),
                      Text('INTERCHANGE', style: GoogleFonts.outfit(color: AppTheme.warningAmber, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 26),
          
          // Itemized Breakdown Scroll
          Text('Accumulated Dishes & Courses History:', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: table.accumulatedItems.length,
              itemBuilder: (context, idx) {
                final item = table.accumulatedItems[idx];
                final price = (item['price'] as num).toDouble();
                final qty = (item['qty'] as num).toInt();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
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
                            Expanded(child: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
                          ],
                        ),
                      ),
                      Text('₹${(price * qty).toStringAsFixed(2)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(color: Colors.white24, height: 20),
          
          // Fiscal Totals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(color: Colors.white70, fontSize: 15)),
              Text('₹${table.subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('5% Dining GST Tax:', style: TextStyle(color: Colors.white70, fontSize: 15)),
              Text('₹${table.gstTax.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total to Collect:', style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              Text('₹${table.totalAmount.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: 26, fontWeight: FontWeight.w900)),
            ],
          ),

          const SizedBox(height: 14),
          Text('Select Tender / Payment Mode:', style: GoogleFonts.outfit(color: AppTheme.warningAmber, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          // Payment Modes Selector
          SizedBox(
            height: isMobile ? 125 : 140,
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
                    width: isMobile ? 135 : 155,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isModeSelected ? AppTheme.primaryEmerald.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isModeSelected ? AppTheme.primaryEmerald : Colors.white12, width: isModeSelected ? 2.5 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(m['icon']!, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 6),
                        Text(m['mode']!, style: GoogleFonts.outfit(color: isModeSelected ? AppTheme.primaryEmerald : Colors.white, fontWeight: FontWeight.w800, fontSize: 12), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(m['desc']!, style: const TextStyle(color: Colors.white54, fontSize: 10), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              icon: isProcessing ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3)) : const Icon(Icons.print, size: 24),
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
              child: Text('Main Cashier Terminal & Settlement Hub', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: isMobile ? 16 : 19), overflow: TextOverflow.ellipsis),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.infoAzure.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.infoAzure)),
                child: Text('${billRequestedTables.length} Awaiting Settlement', style: const TextStyle(color: AppTheme.infoAzure, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu, color: AppTheme.primaryEmerald),
            tooltip: 'View Audit & Interchange Logs',
            onPressed: _showAuditHistoryModal,
          ),
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
