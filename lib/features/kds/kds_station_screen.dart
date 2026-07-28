import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/order_workflow_service.dart';
import '../auth/login_screen.dart';

class KdsStationScreen extends StatefulWidget {
  const KdsStationScreen({super.key});

  @override
  State<KdsStationScreen> createState() => _KdsStationScreenState();
}

class _KdsStationScreenState extends State<KdsStationScreen> {
  final OrderWorkflowService _workflowService = OrderWorkflowService();

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 750;
    final tickets = _workflowService.activeKitchenTickets;

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
              Text('All Kitchen SMA Orders Ready or Served!', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Waiting for Waiters to fire new SMA orders over WebSockets...', style: TextStyle(color: AppTheme.slateGray, fontSize: 16)),
            ],
          ),
        ) : GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: screenWidth < 600 ? 1 : (screenWidth < 1000 ? 2 : 3),
            childAspectRatio: screenWidth < 600 ? 1.15 : 0.9,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final t = tickets[index];
            final isUrgent = t.isUrgent;
            final isReady = t.status == KotStatus.readyToServe;

            return Container(
              decoration: BoxDecoration(
                color: AppTheme.darkCardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isReady ? AppTheme.warningAmber : (isUrgent ? AppTheme.accentCrimson : AppTheme.infoAzure),
                  width: isReady || isUrgent ? 2.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  // Card Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isReady ? AppTheme.warningAmber.withOpacity(0.2) : (isUrgent ? AppTheme.accentCrimson.withOpacity(0.2) : AppTheme.infoAzure.withOpacity(0.15)),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t.id} • ${t.station}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(t.tableName, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isReady ? AppTheme.warningAmber : (isUrgent ? AppTheme.accentCrimson : AppTheme.primaryEmerald),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isReady ? 'READY TO SERVE' : (isUrgent ? 'URGENT FIRING' : 'PREPARING'),
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        )
                      ],
                    ),
                  ),
                  // Items Stream
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: t.items.length,
                      itemBuilder: (context, itemIdx) {
                        final item = t.items[itemIdx];
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
                                    child: Text('${item['qty']}x', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                                ],
                              ),
                              if (item['note'] != null && item['note'].toString().isNotEmpty)
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
                          backgroundColor: isReady ? AppTheme.infoAzure : (isUrgent ? AppTheme.accentCrimson : AppTheme.primaryEmerald),
                          foregroundColor: isReady || !isUrgent ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: Icon(isReady ? Icons.room_service : Icons.flatware),
                        label: Text(
                          isReady ? 'READY FOR WAITER PICKUP' : '👨‍🍳 MARK READY TO SERVE',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                        onPressed: () {
                          if (!isReady) {
                            _workflowService.markTicketReadyToServe(t.id);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              backgroundColor: AppTheme.primaryEmerald,
                              content: Text('✅ ${t.id} marked READY TO SERVE! Waiter notified tableside for pickup.', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                              duration: const Duration(seconds: 3),
                            ));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              backgroundColor: AppTheme.warningAmber,
                              content: Text('🍽️ Dish already marked Ready to Serve! Waiting for Waiter to mark Served.', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                            ));
                          }
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
