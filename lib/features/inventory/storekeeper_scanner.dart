import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class StorekeeperScannerScreen extends StatefulWidget {
  const StorekeeperScannerScreen({super.key});

  @override
  State<StorekeeperScannerScreen> createState() => _StorekeeperScannerScreenState();
}

class _StorekeeperScannerScreenState extends State<StorekeeperScannerScreen> {
  final List<Map<String, dynamic>> items = [
    {'sku': 'ING-TRUFF-01', 'name': 'Black Truffle Oil (Italian)', 'stock': 120, 'unit': 'ml', 'min': 200, 'cost': 12.50},
    {'sku': 'ING-CHOP-02', 'name': 'Smoked Cheddar Cheese', 'stock': 4500, 'unit': 'g', 'min': 2000, 'cost': 1.80},
    {'sku': 'ING-COFF-03', 'name': 'Arabica Espresso Bean Blend', 'stock': 8200, 'unit': 'g', 'min': 3000, 'cost': 1.25},
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkCardBg,
        title: Text('Storekeeper Raw Material Scanner & Audits', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.warningAmber),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPinScreen())),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          children: [
            // Top Stats Hub
            isMobile ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.darkCardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2, color: AppTheme.primaryEmerald, size: 36),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Audited Warehouse Value', style: TextStyle(color: AppTheme.slateGray, fontSize: 13)),
                          Text('₹1,84,320.00', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.infoAzure, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text('SCAN SUPPLIER BARCODE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera scanner ready to process supplier GRN barcode invoices!'))),
                ),
              ],
            ) : Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppTheme.darkCardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2, color: AppTheme.primaryEmerald, size: 40),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Audited Warehouse Value', style: TextStyle(color: AppTheme.slateGray, fontSize: 14)),
                            Text('₹1,84,320.00', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.infoAzure, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text('SCAN SUPPLIER BARCODE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera scanner ready to process supplier GRN barcode invoices!'))),
                )
              ],
            ),
            const SizedBox(height: 20),
            // Inventory Table List
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final it = items[i];
                  final isLow = it['stock'] <= it['min'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isLow ? AppTheme.accentCrimson : Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                                child: Text(it['sku'], style: const TextStyle(color: AppTheme.warningAmber, fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 8),
                              Text(it['name'], style: GoogleFonts.outfit(color: Colors.white, fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              Text('Cost: ₹${it['cost']} / ${it['unit']}', style: TextStyle(color: AppTheme.slateGray, fontSize: isMobile ? 13 : 14)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${it['stock']} ${it['unit']}', style: GoogleFonts.outfit(color: isLow ? AppTheme.accentCrimson : AppTheme.primaryEmerald, fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.w800)),
                                Text('Min: ${it['min']}', style: TextStyle(color: AppTheme.slateGray, fontSize: isMobile ? 12 : 13)),
                              ],
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              style: IconButton.styleFrom(backgroundColor: Colors.white10),
                              icon: const Icon(Icons.add_task, color: AppTheme.primaryEmerald),
                              onPressed: () => setState(() => it['stock'] += 500),
                            )
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
