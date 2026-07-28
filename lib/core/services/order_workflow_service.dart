import 'package:flutter/material.dart';
import '../network/api_client.dart';

enum TableWorkflowStatus { vacant, activeOrder, billFiredToCashier, paid }
enum KotStatus { firedToKitchen, readyToServe, served }

class KotTicket {
  final String id;
  final int tableNumber;
  final String tableName;
  final String station;
  final List<Map<String, dynamic>> items;
  final DateTime timestamp;
  final bool isUrgent;
  KotStatus status;

  KotTicket({
    required this.id,
    required this.tableNumber,
    required this.tableName,
    required this.station,
    required this.items,
    required this.timestamp,
    this.isUrgent = false,
    this.status = KotStatus.firedToKitchen,
  });

  double get ticketTotal {
    double sum = 0;
    for (var item in items) {
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final qty = (item['qty'] as num?)?.toInt() ?? 1;
      sum += price * qty;
    }
    return sum;
  }
}

class TableSession {
  final int tableNumber;
  final String tableName;
  final String zone;
  final int capacity;
  TableWorkflowStatus status;
  List<Map<String, dynamic>> accumulatedItems;
  String? paymentMode;

  TableSession({
    required this.tableNumber,
    required this.tableName,
    required this.zone,
    required this.capacity,
    this.status = TableWorkflowStatus.vacant,
    List<Map<String, dynamic>>? accumulatedItems,
  }) : accumulatedItems = accumulatedItems ?? [];

  double get subtotal {
    double sum = 0;
    for (var item in accumulatedItems) {
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final qty = (item['qty'] as num?)?.toInt() ?? 1;
      sum += price * qty;
    }
    return sum;
  }

  double get gstTax => subtotal * 0.05; // 5% GST for Dining
  double get totalAmount => subtotal + gstTax;
}

class OrderWorkflowService extends ChangeNotifier {
  static final OrderWorkflowService _instance = OrderWorkflowService._internal();
  factory OrderWorkflowService() => _instance;

  OrderWorkflowService._internal() {
    _initializeDemoState();
  }

  final List<TableSession> tables = [
    TableSession(tableNumber: 1, tableName: 'Table T-1 (Main Dining)', zone: 'Lounge', capacity: 4, status: TableWorkflowStatus.vacant),
    TableSession(tableNumber: 2, tableName: 'Table T-2 (Window Side)', zone: 'Lounge', capacity: 2, status: TableWorkflowStatus.vacant),
    TableSession(tableNumber: 3, tableName: 'Table T-3 (VIP Alcove)', zone: 'Lounge', capacity: 6, status: TableWorkflowStatus.activeOrder, accumulatedItems: [
      {'name': 'Truffle & Forest Mushroom Pizza', 'price': 550.0, 'qty': 1, 'note': 'Extra crispy crust'},
      {'name': 'Iced Hazelnut Caramel Latte', 'price': 220.0, 'qty': 2, 'note': 'Less ice'},
    ]),
    TableSession(tableNumber: 4, tableName: 'Table T-4 (Patio Bench)', zone: 'Patio', capacity: 4, status: TableWorkflowStatus.vacant),
    TableSession(tableNumber: 5, tableName: 'Table T-5 (Rooftop Garden)', zone: 'Rooftop', capacity: 4, status: TableWorkflowStatus.activeOrder, accumulatedItems: [
      {'name': 'Smoked Hickory Chicken Burger', 'price': 380.0, 'qty': 2, 'note': 'Medium well'},
      {'name': 'Artisan Pepperoni Deep Dish', 'price': 620.0, 'qty': 1, 'note': 'Add oregano'},
    ]),
    TableSession(tableNumber: 6, tableName: 'ROOF-01 (Sky Lounge)', zone: 'Rooftop', capacity: 8, status: TableWorkflowStatus.billFiredToCashier, accumulatedItems: [
      {'name': 'Pan Seared Atlantic Salmon', 'price': 780.0, 'qty': 2, 'note': 'Lemon butter sauce'},
      {'name': 'Truffle Mushroom Cream Risotto', 'price': 650.0, 'qty': 1, 'note': 'Extra parmigiano'},
      {'name': 'Belgian Chocolate Fondant', 'price': 320.0, 'qty': 2, 'note': 'With vanilla scoop'},
    ]),
  ];

  final List<KotTicket> tickets = [
    KotTicket(
      id: 'SMA-0102',
      tableNumber: 5,
      tableName: 'Table T-5 (Rooftop Garden)',
      station: 'Wood-Fired Oven & Grill',
      items: [
        {'name': 'Smoked Hickory Chicken Burger', 'price': 380.0, 'qty': 2, 'note': 'Medium well'},
        {'name': 'Artisan Pepperoni Deep Dish', 'price': 620.0, 'qty': 1, 'note': 'Add oregano'},
      ],
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      isUrgent: true,
      status: KotStatus.firedToKitchen,
    ),
    KotTicket(
      id: 'SMA-0103',
      tableNumber: 3,
      tableName: 'Table T-3 (VIP Alcove)',
      station: 'Bar & Artisanal Coffee',
      items: [
        {'name': 'Truffle & Forest Mushroom Pizza', 'price': 550.0, 'qty': 1, 'note': 'Extra crispy crust'},
        {'name': 'Iced Hazelnut Caramel Latte', 'price': 220.0, 'qty': 2, 'note': 'Less ice'},
      ],
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      isUrgent: false,
      status: KotStatus.readyToServe, // Ready for waiter pickup!
    ),
  ];

  int _nextSmaNumber = 104;

  void _initializeDemoState() {
    // Pre-loaded state for demonstration
  }

  TableSession getTable(int tableNumber) {
    return tables.firstWhere((t) => t.tableNumber == tableNumber, orElse: () => tables.first);
  }

  List<KotTicket> getTicketsForTable(int tableNumber) {
    return tickets.where((t) => t.tableNumber == tableNumber).toList();
  }

  List<KotTicket> get activeKitchenTickets => tickets.where((t) => t.status == KotStatus.firedToKitchen || t.status == KotStatus.readyToServe).toList();

  List<TableSession> get cashierPendingBills => tables.where((t) => t.status == TableWorkflowStatus.billFiredToCashier).toList();

  // STAGE 1: Waiter fires SMA / KOT Order to Kitchen
  String fireSmaToKitchen({required int tableNumber, required List<Map<String, dynamic>> items, required String station}) {
    final table = getTable(tableNumber);
    final smaId = 'SMA-0$_nextSmaNumber';
    _nextSmaNumber++;

    // Accumulate items onto table invoice
    for (var item in items) {
      table.accumulatedItems.add(Map<String, dynamic>.from(item));
    }
    table.status = TableWorkflowStatus.activeOrder;

    // Create KOT Ticket for Kitchen
    final ticket = KotTicket(
      id: smaId,
      tableNumber: table.tableNumber,
      tableName: table.tableName,
      station: station,
      items: items.map((i) => Map<String, dynamic>.from(i)).toList(),
      timestamp: DateTime.now(),
      status: KotStatus.firedToKitchen,
    );
    tickets.insert(0, ticket);
    notifyListeners();
    
    // Simulate remote backend push
    ApiClient().post('/pos/kot', data: {'table': tableNumber, 'sma_id': smaId, 'items': items}).catchError((_) => null);
    return smaId;
  }

  // STAGE 2: Kitchen Chef marks ready to serve
  void markTicketReadyToServe(String ticketId) {
    final ticket = tickets.firstWhere((t) => t.id == ticketId, orElse: () => tickets.first);
    ticket.status = KotStatus.readyToServe;
    notifyListeners();
    ApiClient().post('/kds/status', data: {'ticket_id': ticketId, 'status': 'ready'}).catchError((_) => null);
  }

  // STAGE 3: Waiter marks order as served tableside
  void markTicketServed(String ticketId) {
    final ticket = tickets.firstWhere((t) => t.id == ticketId, orElse: () => tickets.first);
    ticket.status = KotStatus.served;
    notifyListeners();
    ApiClient().post('/pos/status', data: {'ticket_id': ticketId, 'status': 'served'}).catchError((_) => null);
  }

  // STAGE 4: Waiter closes bill and fires to Cashier
  void closeTableAndFireToCashier(int tableNumber) {
    final table = getTable(tableNumber);
    table.status = TableWorkflowStatus.billFiredToCashier;
    notifyListeners();
    ApiClient().post('/pos/close-bill', data: {'table': tableNumber, 'total': table.totalAmount}).catchError((_) => null);
  }

  // STAGE 5: Cashier collects payment via selected mode & prints thermal receipt
  void settleTableBill({required int tableNumber, required String paymentMode}) {
    final table = getTable(tableNumber);
    table.status = TableWorkflowStatus.paid;
    table.paymentMode = paymentMode;
    
    // Send ESC/POS printing signal to dynamic kitchen/cashier thermal printer IP
    print('Firing fiscal thermal invoice to printer at ${ApiClient.printerIp} for Table ${table.tableNumber} (₹${table.totalAmount.toStringAsFixed(2)} via $paymentMode)');
    
    // Clear table for turnover after brief delay or immediately reset to vacant
    Future.delayed(const Duration(milliseconds: 1500), () {
      table.status = TableWorkflowStatus.vacant;
      table.accumulatedItems.clear();
      table.paymentMode = null;
      tickets.removeWhere((t) => t.tableNumber == tableNumber && t.status == KotStatus.served);
      notifyListeners();
    });
    
    notifyListeners();
    ApiClient().post('/accounts/invoices', data: {'table': tableNumber, 'total': table.totalAmount, 'mode': paymentMode}).catchError((_) => null);
  }
}
