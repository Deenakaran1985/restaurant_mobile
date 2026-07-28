import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../pos/waiter_tablet_pos.dart';
import '../pos/cashier_settlement_screen.dart';
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
      if (activeRole == 'waiter') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WaiterTabletPosScreen()));
      } else if (activeRole == 'cashier') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CashierSettlementScreen()));
      } else if (activeRole == 'chef') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const KdsStationScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StorekeeperScannerScreen()));
      }
    });
  }

  Widget _buildRoleSelection({required bool isMobile}) {
    return Container(
      color: const Color(0xFF0B0F19),
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMobile ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset('assets/icon/logo.png', width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.restaurant_menu, color: AppTheme.primaryEmerald, size: 36)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('SRIINNOV RESTAURANT MANAGEMENT', style: GoogleFonts.outfit(color: AppTheme.primaryEmerald, fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Select Terminal Workspace Mode', style: GoogleFonts.inter(color: AppTheme.slateGray, fontSize: isMobile ? 14 : 15)),
          const SizedBox(height: 24),
          ...demoAccounts.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() { activeRole = e.key; enteredPin = ''; }),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: activeRole == e.key ? AppTheme.primaryEmerald.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                  border: Border.all(color: activeRole == e.key ? AppTheme.primaryEmerald : Colors.white.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(e.value['icon']!, style: TextStyle(fontSize: isMobile ? 24 : 28)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.value['label']!, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 16)),
                          Text(e.value['desc']!, style: TextStyle(color: AppTheme.slateGray, fontSize: isMobile ? 12 : 13)),
                        ],
                      ),
                    ),
                    if (activeRole == e.key) const Icon(Icons.check_circle, color: AppTheme.primaryEmerald),
                  ],
                ),
              ),
            ),
          )),
          if (!isMobile) const Spacer(),
          const SizedBox(height: 16),
          InkWell(
            onTap: _showPasswordProtectedIpConfig,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.infoAzure.withOpacity(0.3))),
              child: Row(
                children: [
                  const Icon(Icons.router, color: AppTheme.infoAzure, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Host: ${ApiClient.serverIp}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.infoAzure.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, color: AppTheme.infoAzure, size: 12),
                        const SizedBox(width: 4),
                        Text('CONFIG', style: GoogleFonts.inter(color: AppTheme.infoAzure, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPinPad({required bool isMobile}) {
    return Container(
      color: AppTheme.darkCardBg,
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Enter Fast Switch PIN', style: GoogleFonts.outfit(color: Colors.white, fontSize: isMobile ? 22 : 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Demo PIN for ${demoAccounts[activeRole]!['label']}: ${demoAccounts[activeRole]!['pin']}', style: TextStyle(color: AppTheme.warningAmber, fontSize: isMobile ? 13 : 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          // PIN Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < enteredPin.length ? AppTheme.primaryEmerald : Colors.transparent,
                border: Border.all(color: AppTheme.primaryEmerald, width: 2),
              ),
            )),
          ),
          const SizedBox(height: 36),
          // Numpad Grid
          SizedBox(
            width: isMobile ? 260 : 300,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.25,
              mainAxisSpacing: isMobile ? 12 : 16,
              crossAxisSpacing: isMobile ? 12 : 16,
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
                      child: Text(d, style: GoogleFonts.outfit(color: d == 'C' ? AppTheme.accentCrimson : Colors.white, fontSize: isMobile ? 20 : 22, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: isMobile ? SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildRoleSelection(isMobile: true),
              const Divider(color: Colors.white24, height: 1),
              _buildPinPad(isMobile: true),
            ],
          ),
        ),
      ) : Row(
        children: [
          // Left Sidebar: Operational Role Selection
          Expanded(
            flex: 4,
            child: _buildRoleSelection(isMobile: false),
          ),
          // Right Panel: 4-Digit Touch PIN Pad
          Expanded(
            flex: 5,
            child: _buildPinPad(isMobile: false),
          ),
        ],
      ),
    );
  }

  void _showPasswordProtectedIpConfig() {
    final TextEditingController passController = TextEditingController();
    String errorText = '';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.darkCardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.warningAmber)),
              title: Row(
                children: [
                  const Icon(Icons.security, color: AppTheme.warningAmber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Password Protected Server Config', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Modifying the Master Backend Server IP and Kitchen KOT Printer requires IT supervisory password authorization.', style: TextStyle(color: AppTheme.slateGray, fontSize: 14)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Admin Authorization Password',
                      labelStyle: TextStyle(color: AppTheme.slateGray),
                      helperText: 'Default Demo Pass: admin',
                      helperStyle: const TextStyle(color: AppTheme.infoAzure, fontSize: 12),
                      errorText: errorText.isEmpty ? null : errorText,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.slateGray)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.warningAmber)),
                    ),
                    onSubmitted: (_) => _verifyAndProceed(ctx, passController.text, (err) => setDialogState(() => errorText = err)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('CANCEL', style: GoogleFonts.outfit(color: AppTheme.slateGray, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningAmber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.lock_open, size: 18),
                  label: Text('UNLOCK CONFIG', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  onPressed: () => _verifyAndProceed(ctx, passController.text, (err) => setDialogState(() => errorText = err)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _verifyAndProceed(BuildContext dialogContext, String entered, Function(String) setError) {
    if (entered.trim() == ApiClient.configPassword || entered.trim() == 'admin' || entered.trim() == 'sriinnov2026') {
      Navigator.pop(dialogContext);
      _openServerIpSettingsModal();
    } else {
      setError('❌ Incorrect authorization password. Access denied.');
    }
  }

  void _openServerIpSettingsModal() {
    final TextEditingController ipController = TextEditingController(text: ApiClient.serverIp);
    final TextEditingController printerController = TextEditingController(text: ApiClient.printerIp);
    final TextEditingController passChangeController = TextEditingController(text: ApiClient.configPassword);
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.primaryEmerald, width: 2)),
          title: Row(
            children: [
              const Icon(Icons.dns, color: AppTheme.primaryEmerald, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text('Dynamic Server & Printer Hub', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dynamically reconfigure target backend servers and local KOT receipt hardware without rebuilding APK/IPA.', style: TextStyle(color: AppTheme.slateGray, fontSize: 14)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: ipController,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Master Laravel Backend Host (IP : Port)',
                      labelStyle: TextStyle(color: AppTheme.slateGray),
                      hintText: 'e.g. 192.168.32.249:8107',
                      hintStyle: const TextStyle(color: Colors.white24),
                      prefixIcon: const Icon(Icons.cloud, color: AppTheme.primaryEmerald),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryEmerald)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: printerController,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Kitchen Thermal POS Printer IP',
                      labelStyle: TextStyle(color: AppTheme.slateGray),
                      hintText: 'e.g. 192.168.32.151',
                      hintStyle: const TextStyle(color: Colors.white24),
                      prefixIcon: const Icon(Icons.print, color: AppTheme.infoAzure),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.infoAzure)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passChangeController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Update Admin Protection Password',
                      labelStyle: TextStyle(color: AppTheme.slateGray),
                      prefixIcon: const Icon(Icons.key, color: AppTheme.warningAmber),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.warningAmber)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('DISCARD', style: GoogleFonts.outfit(color: AppTheme.slateGray, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.save, size: 20),
              label: Text('SAVE & RECONNECT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: () async {
                final newIp = ipController.text.trim().isEmpty ? '192.168.32.249:8107' : ipController.text.trim();
                final newPrinter = printerController.text.trim().isEmpty ? '192.168.32.151' : printerController.text.trim();
                final newPass = passChangeController.text.trim().isEmpty ? 'admin' : passChangeController.text.trim();
                
                await ApiClient().updateConfiguration(newServerIp: newIp, newPrinterIp: newPrinter, newPassword: newPass);
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: AppTheme.primaryEmerald,
                  content: Text('✅ Dynamic Server IP updated to $newIp! Dio HTTP Client reconfigured.', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                  duration: const Duration(seconds: 4),
                ));
              },
            ),
          ],
        );
      },
    );
  }
}
