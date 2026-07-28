import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class KdsStationScreen extends StatefulWidget {
  const KdsStationScreen({super.key});

  @override
  State<KdsStationScreen> createState() => _KdsStationScreenState();
}

class _KdsStationScreenState extends State<KdsStationScreen> {
  List<Map<String, dynamic>> tickets = [
    {
      'id': 'ORD-0092',
      'table': 'Table T-3 (Main Lounge)',
      'time': '14m ago',
      'urgent': true,
      'station': 'Wood-Fired Oven',
      'items': [
        {'name': 'Truffle & Forest Mushroom Pizza', 'qty': 1, 'note': 'Extra crisp edge'},
      ]
    },
    {
      'id': 'ORD-0094',
      'table': 'Table T-5 (Rooftop Garden)',
      'time': '4m ago',
      'urgent': false,
      'station': 'Bar / Beverages',
      'items': [
        {'name': 'Iced Hazelnut Caramel Latte', 'qty': 2, 'note': 'Less Sugar'},
        {'name': 'Warm Belgian Lava Cake', 'qty': 1, 'note': 'Add Vanilla Scoop'},
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 750;
    return Scaffold(
      backgroundColor: const Color(0xFF090D16), // Ultra dark kitchen ambiance
      appBar: AppBar(
        backgroundColor: AppTheme.darkCardBg,
        title: Row(
          children: [
            const Icon(Icons.display_settings, color: AppTheme.warningAmber),
            const SizedBox(width: 10),
            Flexible(
              child: Text('Kitchen Touch Display (KDS Station)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 18), overflow: TextOverflow.ellipsis),
            ),
            if (!isMobile) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.warningAmber.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.warningAmber)),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up, color: AppTheme.warningAmber, size: 18),
                    const SizedBox(width: 6),
                    Text('BUZZER CHIME ACTIVE', style: GoogleFonts.inter(color: AppTheme.warningAmber, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.accentCrimson),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPinScreen())),
            )
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: tickets.isEmpty ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: AppTheme.primaryEmerald, size: 80),
              const SizedBox(height: 16),
              Text('All Kitchen Orders Served!', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Waiting for Waiters to fire new KOTs over WebSockets...', style: TextStyle(color: AppTheme.slateGray, fontSize: 16)),
            ],
          ),
        ) : GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: screenWidth < 600 ? 1 : (screenWidth < 1000 ? 2 : 3),
            childAspectRatio: screenWidth < 600 ? 1.25 : 0.95,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final t = tickets[index];
            final isUrgent = t['urgent'] as bool;
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.darkCardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isUrgent ? AppTheme.accentCrimson : AppTheme.infoAzure, width: isUrgent ? 2.5 : 1),
              ),
              child: Column(
                children: [
                  // Card Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUrgent ? AppTheme.accentCrimson.withOpacity(0.2) : AppTheme.infoAzure.withOpacity(0.15),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['id'], style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            Text(t['table'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: isUrgent ? AppTheme.accentCrimson : AppTheme.warningAmber, borderRadius: BorderRadius.circular(10)),
                          child: Text(t['time'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        )
                      ],
                    ),
                  ),
                  // Items Stream
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: (t['items'] as List).length,
                      itemBuilder: (context, itemIdx) {
                        final item = t['items'][itemIdx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: AppTheme.primaryEmerald, borderRadius: BorderRadius.circular(6)),
                                    child: Text('${item['qty']}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                                ],
                              ),
                              if (item['note'] != null && item['note'].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6, left: 34),
                                  child: Text('⚠️ Note: ${item['note']}', style: const TextStyle(color: AppTheme.warningAmber, fontSize: 13, fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Action Tap Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isUrgent ? AppTheme.accentCrimson : AppTheme.primaryEmerald,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.done_all),
                        label: Text('MARK SERVED & DEDUCT COGS', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          setState(() => tickets.removeAt(index));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket marked ready! Automated recipe inventory deduction triggered via backend.')));
                        },
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
