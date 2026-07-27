import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../pos/waiter_tablet_pos.dart';
import '../kds/kds_station_screen.dart';
import '../inventory/storekeeper_scanner.dart';

class LoginPinScreen extends StatefulWidget {
  const LoginPinScreen({super.key});

  @override
  State<LoginPinScreen> createState() => _LoginPinScreenState();
}

class _LoginPinScreenState extends State<LoginPinScreen> {
  String enteredPin = '';
  String activeRole = 'waiter';

  final Map<String, Map<String, String>> demoAccounts = {
    'waiter': {'label': 'Lead Waiter', 'pin': '7777', 'icon': '🍴', 'desc': 'Tableside KOT Tablet & QR Orders'},
    'chef': {'label': 'Executive Chef (KDS)', 'pin': '5555', 'icon': '🔥', 'desc': 'Kitchen Touch Station & SLA Timers'},
    'cashier': {'label': 'Main Cashier', 'pin': '8888', 'icon': '💳', 'desc': 'POS Invoicing & ESC/POS Thermal Print'},
    'storekeeper': {'label': 'Store Keeper', 'pin': '9999', 'icon': '📦', 'desc': 'Raw Material Intake & Shelf Auditing'},
  };

  void onDigitTap(String digit) {
    if (enteredPin.length < 4) {
      setState(() => enteredPin += digit);
      if (enteredPin.length == 4) {
        verifyAndRedirect();
      }
    }
  }

  void verifyAndRedirect() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (activeRole == 'waiter' || activeRole == 'cashier') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WaiterTabletPosScreen()));
      } else if (activeRole == 'chef') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const KdsStationScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StorekeeperScannerScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar: Operational Role Selection
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFF0B0F19),
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('ANTIGRAVITY ERP', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Select Terminal Workspace Mode', style: GoogleFonts.inter(color: AppTheme.slateGray, fontSize: 15)),
                  const SizedBox(height: 32),
                  ...demoAccounts.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => setState(() { activeRole = e.key; enteredPin = ''; }),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: activeRole == e.key ? AppTheme.primaryEmerald.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                          border: Border.all(color: activeRole == e.key ? AppTheme.primaryEmerald : Colors.white.withOpacity(0.08)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text(e.value['icon']!, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.value['label']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(e.value['desc']!, style: TextStyle(color: AppTheme.slateGray, fontSize: 13)),
                                ],
                              ),
                            ),
                            if (activeRole == e.key) const Icon(Icons.check_circle, color: AppTheme.primaryEmerald),
                          ],
                        ),
                      ),
                    ),
                  )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.router, color: AppTheme.infoAzure, size: 20),
                        const SizedBox(width: 8),
                        Text('Host: 192.168.32.249:8107', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          // Right Panel: 4-Digit Touch PIN Pad
          Expanded(
            flex: 5,
            child: Container(
              color: AppTheme.darkCardBg,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Enter Fast Switch PIN', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Demo PIN for ${demoAccounts[activeRole]!['label']}: ${demoAccounts[activeRole]!['pin']}', style: const TextStyle(color: AppTheme.warningAmber, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  // PIN Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < enteredPin.length ? AppTheme.primaryEmerald : Colors.transparent,
                        border: Border.all(color: AppTheme.primaryEmerald, width: 2),
                      ),
                    )),
                  ),
                  const SizedBox(height: 48),
                  // Numpad Grid
                  SizedBox(
                    width: 300,
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      childAspectRatio: 1.2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var d in ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '←'])
                          InkWell(
                            onTap: () {
                              if (d == 'C') setState(() => enteredPin = '');
                              else if (d == '←' && enteredPin.isNotEmpty) setState(() => enteredPin = enteredPin.substring(0, enteredPin.length - 1));
                              else if (d != 'C' && d != '←') onDigitTap(d);
                            },
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: d == 'C' ? AppTheme.accentCrimson.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                              child: Text(d, style: GoogleFonts.outfit(color: d == 'C' ? AppTheme.accentCrimson : Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
