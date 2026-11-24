// UI Modern Flutter - Food Ordering App (Login, Menu, Checkout, Notification)
// main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'pages/inventory_management_page.dart';

void main() {
  runApp(const FoodApp());
}

// ================= ENUMS =================
enum UserRole { admin, cashier, customer }

enum ProductCategory { makanan, minuman, snack }

// ================= MODELS =================
class MenuItem {
  final String id;
  String name;
  int price;
  int stock;
  ProductCategory category;
  String? imageUrl;
  DateTime lastUpdated;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    this.imageUrl,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  MenuItem copyWith({
    String? id,
    String? name,
    int? price,
    int? stock,
    ProductCategory? category,
    String? imageUrl,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      lastUpdated: DateTime.now(),
    );
  }
}

class CartItem {
  MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  int get totalPrice => menuItem.price * quantity;
}

class User {
  String name;
  UserRole role;
  int? tableNumber;

  User({required this.name, required this.role, this.tableNumber});
}

class Order {
  final String id;
  final User customer;
  final List<CartItem> items;
  final int totalPrice;
  final DateTime orderTime;
  String status; // pending, confirmed, waiting_payment, paid
  String notes; // Catatan pelanggan untuk pesanan
  String paymentStatus; // unpaid, paid
  DateTime? paymentConfirmedTime; // Waktu pembayaran dikonfirmasi
  DateTime? confirmedTime; // Waktu pesanan dikonfirmasi oleh kasir
  bool archived; // apakah dipindahkan ke riwayat

  Order({
    required this.id,
    required this.customer,
    required this.items,
    required this.totalPrice,
    required this.status,
    DateTime? orderTime,
    this.notes = '',
    this.paymentStatus = 'unpaid',
    this.paymentConfirmedTime,
    this.confirmedTime,
    this.archived = false,
  }) : orderTime = orderTime ?? DateTime.now();
}

// ================= ADMIN & CASHIER CREDENTIALS =================
class UserCredential {
  final String username;
  final String password;
  final UserRole role;
  final String displayName;

  UserCredential({
    required this.username,
    required this.password,
    required this.role,
    required this.displayName,
  });
}

class AuthData {
  static final List<UserCredential> credentials = [
    // Admin credentials
    UserCredential(
      username: 'admin',
      password: 'admin',
      role: UserRole.admin,
      displayName: 'Administrator',
    ),
    // Kasir (Cashier) credentials
    UserCredential(
      username: 'kasir',
      password: 'kasir',
      role: UserRole.cashier,
      displayName: 'Kasir',
    ),
  ];

  // Method untuk validasi login
  static UserCredential? validateLogin(
    String username,
    String password,
    UserRole role,
  ) {
    try {
      final user = credentials.firstWhere(
        (cred) =>
            cred.username == username &&
            cred.password == password &&
            cred.role == role,
      );
      return user;
    } catch (e) {
      return null;
    }
  }
}

// ================= DATA PERSISTENCE =================
class DataPersistence {
  static const String menuKey = 'menu_items';
  static const String ordersKey = 'orders_data';
  static const String debugKey = 'last_save_timestamp';

  /// Simpan menu items ke storage dengan error handling yang robust
  static Future<bool> saveMenuItems(List<MenuItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) {
        return {
          'id': item.id,
          'name': item.name,
          'price': item.price,
          'stock': item.stock,
          'category': item.category.toString(),
          'imageUrl': item.imageUrl,
          'lastUpdated': item.lastUpdated.toIso8601String(),
        };
      }).toList();

      final jsonString = jsonEncode(jsonList);

      // Simpan data
      final success = await prefs.setString(menuKey, jsonString);

      // Log untuk debugging
      await prefs.setString(debugKey, DateTime.now().toIso8601String());

      if (success) {
        print('✓ Menu items berhasil disimpan: ${items.length} items');
        return true;
      } else {
        print('✗ Gagal menyimpan menu items');
        return false;
      }
    } catch (e) {
      print('✗ Error saat menyimpan menu items: $e');
      return false;
    }
  }

  /// Load menu items dari storage
  static Future<List<MenuItem>> loadMenuItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(menuKey);

      if (jsonStr == null || jsonStr.isEmpty) {
        print('⚠ Data menu tidak ditemukan di storage');
        return [];
      }

      final jsonList = jsonDecode(jsonStr) as List;
      final items = jsonList.map((json) {
        final categoryStr = (json['category'] as String).split('.')[1];
        return MenuItem(
          id: json['id'],
          name: json['name'],
          price: json['price'],
          stock: json['stock'],
          category: ProductCategory.values.firstWhere(
            (e) => e.name == categoryStr,
          ),
          imageUrl: json['imageUrl'],
          lastUpdated: DateTime.parse(json['lastUpdated']),
        );
      }).toList();

      print('✓ Menu items berhasil dimuat: ${items.length} items');
      return items;
    } catch (e) {
      print('✗ Error saat memuat menu items: $e');
      return [];
    }
  }

  /// Simpan orders ke storage dengan error handling yang robust
  static Future<bool> saveOrders(List<Order> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = orders.map((order) {
        return {
          'id': order.id,
          'customerName': order.customer.name,
          'customerRole': order.customer.role.toString(),
          'tableNumber': order.customer.tableNumber,
          'totalPrice': order.totalPrice,
          'orderTime': order.orderTime.toIso8601String(),
          'status': order.status,
          'paymentStatus': order.paymentStatus,
          'confirmedTime': order.confirmedTime?.toIso8601String(),
          'paymentConfirmedTime': order.paymentConfirmedTime?.toIso8601String(),
          'archived': order.archived,
          'items': order.items
              .map(
                (cartItem) => {
                  'menuItemId': cartItem.menuItem.id,
                  'menuItemName': cartItem.menuItem.name,
                  'menuItemPrice': cartItem.menuItem.price,
                  'menuItemStock': cartItem.menuItem.stock,
                  'menuItemCategory': cartItem.menuItem.category.toString(),
                  'menuItemImageUrl': cartItem.menuItem.imageUrl,
                  'quantity': cartItem.quantity,
                },
              )
              .toList(),
          'notes': order.notes,
        };
      }).toList();

      final jsonString = jsonEncode(jsonList);
      final success = await prefs.setString(ordersKey, jsonString);

      if (success) {
        print('✓ Orders berhasil disimpan: ${orders.length} orders');
        return true;
      } else {
        print('✗ Gagal menyimpan orders');
        return false;
      }
    } catch (e) {
      print('✗ Error saat menyimpan orders: $e');
      return false;
    }
  }

  /// Load orders dari storage
  static Future<List<Order>> loadOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(ordersKey);

      if (jsonStr == null || jsonStr.isEmpty) {
        print('⚠ Data orders tidak ditemukan di storage');
        return [];
      }

      final jsonList = jsonDecode(jsonStr) as List;
      final orders = jsonList.map((json) {
        // Load items dari JSON
        List<CartItem> loadedItems = [];
        if (json['items'] != null && json['items'] is List) {
          loadedItems = (json['items'] as List).map((itemJson) {
            final categoryStr = (itemJson['menuItemCategory'] as String).split(
              '.',
            )[1];
            final menuItem = MenuItem(
              id: itemJson['menuItemId'],
              name: itemJson['menuItemName'],
              price: itemJson['menuItemPrice'],
              stock: itemJson['menuItemStock'],
              category: ProductCategory.values.firstWhere(
                (e) => e.name == categoryStr,
              ),
              imageUrl: itemJson['menuItemImageUrl'],
            );
            return CartItem(menuItem: menuItem, quantity: itemJson['quantity']);
          }).toList();
        }

        return Order(
          id: json['id'],
          customer: User(
            name: json['customerName'],
            role: UserRole.customer,
            tableNumber: json['tableNumber'],
          ),
          items: loadedItems,
          totalPrice: json['totalPrice'],
          status: json['status'],
          orderTime: DateTime.parse(json['orderTime']),
          notes: json['notes'] ?? '',
          paymentStatus: json['paymentStatus'] ?? 'unpaid',
          confirmedTime: json['confirmedTime'] != null
              ? DateTime.parse(json['confirmedTime'])
              : null,
          paymentConfirmedTime: json['paymentConfirmedTime'] != null
              ? DateTime.parse(json['paymentConfirmedTime'])
              : null,
          archived: json['archived'] ?? false,
        );
      }).toList();

      print('✓ Orders berhasil dimuat: ${orders.length} orders');
      return orders;
    } catch (e) {
      print('✗ Error saat memuat orders: $e');
      return [];
    }
  }

  /// Verifikasi data tersimpan (untuk debugging)
  static Future<void> verifyStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final menuData = prefs.getString(menuKey);
      final ordersData = prefs.getString(ordersKey);

      print('=== VERIFIKASI DATA STORAGE ===');
      print('Menu items tersimpan: ${menuData != null ? 'Ya' : 'Tidak'}');
      print('Orders tersimpan: ${ordersData != null ? 'Ya' : 'Tidak'}');
      if (menuData != null) {
        final items = jsonDecode(menuData) as List;
        print('Jumlah menu items: ${items.length}');
      }
      if (ordersData != null) {
        final orders = jsonDecode(ordersData) as List;
        print('Jumlah orders: ${orders.length}');
      }
      print('=============================');
    } catch (e) {
      print('✗ Error saat verifikasi: $e');
    }
  }
}

// ================= REVENUE HISTORY PERSISTENCE =================
/// Sistem untuk melacak riwayat pendapatan terpisah dari pesanan
/// Ketika pesanan dihapus, data pendapatan tetap tersimpan untuk analytics
class RevenueHistory {
  final String id;
  final int amount;
  final DateTime recordedDate;
  final DateTime? originalOrderTime;
  final String source; // 'paid_order', 'archived', 'deleted'

  RevenueHistory({
    required this.id,
    required this.amount,
    required this.recordedDate,
    this.originalOrderTime,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'recordedDate': recordedDate.toIso8601String(),
    'originalOrderTime': originalOrderTime?.toIso8601String(),
    'source': source,
  };

  factory RevenueHistory.fromJson(Map<String, dynamic> json) => RevenueHistory(
    id: json['id'],
    amount: json['amount'],
    recordedDate: DateTime.parse(json['recordedDate']),
    originalOrderTime: json['originalOrderTime'] != null
        ? DateTime.parse(json['originalOrderTime'])
        : null,
    source: json['source'],
  );
}

class RevenueHistoryPersistence {
  static const String revenueHistoryKey = 'revenue_history';

  /// Simpan riwayat pendapatan ke storage
  static Future<bool> saveRevenueHistory(List<RevenueHistory> revenues) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = revenues.map((r) => r.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      final success = await prefs.setString(revenueHistoryKey, jsonString);

      if (success) {
        print(
          '✓ Revenue history berhasil disimpan: ${revenues.length} records',
        );
        return true;
      }
      return false;
    } catch (e) {
      print('✗ Error saat menyimpan revenue history: $e');
      return false;
    }
  }

  /// Load riwayat pendapatan dari storage
  static Future<List<RevenueHistory>> loadRevenueHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(revenueHistoryKey);

      if (jsonStr == null || jsonStr.isEmpty) {
        print('⚠ Revenue history tidak ditemukan di storage');
        return [];
      }

      final jsonList = jsonDecode(jsonStr) as List;
      final revenues = jsonList
          .map((json) => RevenueHistory.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✓ Revenue history berhasil dimuat: ${revenues.length} records');
      return revenues;
    } catch (e) {
      print('✗ Error saat memuat revenue history: $e');
      return [];
    }
  }

  /// Tambahkan pendapatan dari order yang dibayar
  static Future<bool> recordPaidOrderRevenue(Order order) async {
    try {
      final histories = await loadRevenueHistory();

      // Cek apakah revenue ini sudah tercatat
      final exists = histories.any((h) => h.id == 'order_${order.id}');
      if (exists) {
        return true; // Sudah tercatat, jangan tambahkan lagi
      }

      final newRevenue = RevenueHistory(
        id: 'order_${order.id}',
        amount: order.totalPrice,
        recordedDate: DateTime.now(),
        originalOrderTime: order.orderTime,
        source: 'paid_order',
      );

      histories.add(newRevenue);
      return await saveRevenueHistory(histories);
    } catch (e) {
      print('✗ Error saat recording paid order: $e');
      return false;
    }
  }

  /// Simpan pendapatan sebelum order dihapus
  static Future<bool> recordDeletedOrderRevenue(Order order) async {
    try {
      final histories = await loadRevenueHistory();

      if (order.status == 'paid') {
        // Cek apakah sudah ada record untuk order ini
        final exists = histories.any((h) => h.id == 'order_${order.id}');

        if (!exists) {
          final deletedRevenue = RevenueHistory(
            id: 'order_${order.id}',
            amount: order.totalPrice,
            recordedDate: DateTime.now(),
            originalOrderTime: order.orderTime,
            source: 'deleted',
          );
          histories.add(deletedRevenue);
        }
      }

      return await saveRevenueHistory(histories);
    } catch (e) {
      print('✗ Error saat recording deleted order: $e');
      return false;
    }
  }

  /// Hitung revenue dari history berdasarkan periode waktu yang akurat
  /// - today: 24 jam terakhir
  /// - week: 7 hari terakhir
  /// - month: 30 hari terakhir
  /// - year: 365 hari terakhir
  static Future<Map<String, int>> calculateHistoricalRevenue() async {
    try {
      final histories = await loadRevenueHistory();
      final now = DateTime.now();

      int todayRevenue = 0;
      int weekRevenue = 0;
      int monthRevenue = 0;
      int yearRevenue = 0;

      for (var record in histories) {
        final originalTime = record.originalOrderTime ?? record.recordedDate;
        final daysDifference = now.difference(originalTime).inDays;
        final hoursDifference = now.difference(originalTime).inHours;

        // Hitung tahun (365 hari terakhir)
        if (daysDifference >= 0 && daysDifference < 365) {
          yearRevenue += record.amount;

          // Hitung bulan (30 hari terakhir)
          if (daysDifference < 30) {
            monthRevenue += record.amount;

            // Hitung minggu (7 hari terakhir)
            if (daysDifference < 7) {
              weekRevenue += record.amount;

              // Hitung hari (24 jam terakhir)
              if (hoursDifference < 24) {
                todayRevenue += record.amount;
              }
            }
          }
        }
      }

      return {
        'today': todayRevenue,
        'week': weekRevenue,
        'month': monthRevenue,
        'year': yearRevenue,
      };
    } catch (e) {
      print('✗ Error saat menghitung historical revenue: $e');
      return {'today': 0, 'week': 0, 'month': 0, 'year': 0};
    }
  }
}

// ================= ANALYTICS CALCULATOR =================
class AnalyticsCalculator {
  /// Hitung revenue dari current orders berdasarkan periode waktu yang akurat
  /// - today: 24 jam terakhir
  /// - week: 7 hari terakhir
  /// - month: 30 hari terakhir
  /// - year: 365 hari terakhir
  static Map<String, int> calculateRevenue(List<Order> orders) {
    final now = DateTime.now();
    int todayRevenue = 0;
    int weekRevenue = 0;
    int monthRevenue = 0;
    int yearRevenue = 0;

    for (var order in orders) {
      if (order.status == 'paid') {
        final daysDifference = now.difference(order.orderTime).inDays;
        final hoursDifference = now.difference(order.orderTime).inHours;

        // Hitung tahun (365 hari terakhir)
        if (daysDifference >= 0 && daysDifference < 365) {
          yearRevenue += order.totalPrice;

          // Hitung bulan (30 hari terakhir)
          if (daysDifference < 30) {
            monthRevenue += order.totalPrice;

            // Hitung minggu (7 hari terakhir)
            if (daysDifference < 7) {
              weekRevenue += order.totalPrice;

              // Hitung hari (24 jam terakhir)
              if (hoursDifference < 24) {
                todayRevenue += order.totalPrice;
              }
            }
          }
        }
      }
    }

    return {
      'today': todayRevenue,
      'week': weekRevenue,
      'month': monthRevenue,
      'year': yearRevenue,
    };
  }

  /// Hitung revenue gabungan dari current orders + historical revenue
  /// Metode ini digunakan di dashboard untuk menampilkan total pendapatan
  /// termasuk dari pesanan yang sudah dihapus
  static Future<Map<String, int>> calculateCombinedRevenue(
    List<Order> orders,
  ) async {
    // Hitung revenue dari current orders
    final currentRevenue = calculateRevenue(orders);

    // Hitung revenue dari history (pesanan yang sudah dihapus)
    final historicalRevenue =
        await RevenueHistoryPersistence.calculateHistoricalRevenue();

    // Gabungkan keduanya
    return {
      'today':
          (currentRevenue['today'] ?? 0) + (historicalRevenue['today'] ?? 0),
      'week': (currentRevenue['week'] ?? 0) + (historicalRevenue['week'] ?? 0),
      'month':
          (currentRevenue['month'] ?? 0) + (historicalRevenue['month'] ?? 0),
      'year': (currentRevenue['year'] ?? 0) + (historicalRevenue['year'] ?? 0),
    };
  }

  static String formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

// ================= RECEIPT/NOTA PAGE =================
class ReceiptPage extends StatelessWidget {
  final Order order;

  const ReceiptPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Struk Pesanan"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Receipt Container
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header
                  const Text(
                    "WARUNG CAK AMIN",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Aplikasi Pemesanan Makanan",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Order Info
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Nama: ${order.customer.name}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Meja: ${order.customer.tableNumber}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          "No. Pesanan: ${order.id.substring(0, 8)}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          "Waktu: ${_formatTime(order.orderTime)}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Catatan Pelanggan (jika ada)
                  if (order.notes.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "CATATAN PELANGGAN",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            order.notes,
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                  ],

                  // Items List
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "DAFTAR PESANAN",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...order.items.asMap().entries.map((entry) {
                          final item = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "${item.menuItem.name} x${item.quantity}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Text(
                                  "Rp ${AnalyticsCalculator.formatCurrency(item.totalPrice)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TOTAL",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Rp ${AnalyticsCalculator.formatCurrency(order.totalPrice)}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Status: ${_getStatusText(order.status)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(order.status),
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    "Terima kasih telah berkunjung",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text("Salin Teks"),
                    onPressed: () {
                      _generateReceiptText();
                      // Copy to clipboard would require url_launcher package
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Teks struk telah disiapkan untuk disalin",
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text("Cetak"),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Fitur cetak sedang disiapkan"),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'MENUNGGU KONFIRMASI';
      case 'waiting_payment':
        return 'MENUNGGU PEMBAYARAN';
      case 'confirmed':
        return 'DIKONFIRMASI';
      case 'paid':
        return 'SUDAH DIBAYAR';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'waiting_payment':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _generateReceiptText() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("═══════════════════════════════════");
    buffer.writeln("       WARUNG CAK AMIN");
    buffer.writeln("    Aplikasi Pemesanan Makanan");
    buffer.writeln("═══════════════════════════════════");
    buffer.writeln("Nama: ${order.customer.name}");
    buffer.writeln("Meja: ${order.customer.tableNumber}");
    buffer.writeln("No. Pesanan: ${order.id.substring(0, 8)}");
    buffer.writeln("Waktu: ${_formatTime(order.orderTime)}");
    buffer.writeln("───────────────────────────────────");
    // Tambahkan catatan jika ada
    if (order.notes.isNotEmpty) {
      buffer.writeln("CATATAN: ${order.notes}");
      buffer.writeln("───────────────────────────────────");
    }
    buffer.writeln("DAFTAR PESANAN");
    for (var item in order.items) {
      buffer.writeln(
        "${item.menuItem.name} x${item.quantity} = Rp ${AnalyticsCalculator.formatCurrency(item.totalPrice)}",
      );
    }
    buffer.writeln("───────────────────────────────────");
    buffer.writeln(
      "TOTAL: Rp ${AnalyticsCalculator.formatCurrency(order.totalPrice)}",
    );
    buffer.writeln("Status: ${_getStatusText(order.status)}");
    buffer.writeln("═══════════════════════════════════");
    buffer.writeln("Terima kasih telah berkunjung");
    return buffer.toString();
  }
}

// ================= INVENTORY ANALYTICS PAGE =================
class InventoryAnalyticsPage extends StatefulWidget {
  final List<MenuItem> menuItems;
  final List<Order> allOrders;

  const InventoryAnalyticsPage({
    super.key,
    required this.menuItems,
    required this.allOrders,
  });

  @override
  State<InventoryAnalyticsPage> createState() => _InventoryAnalyticsPageState();
}

class _InventoryAnalyticsPageState extends State<InventoryAnalyticsPage> {
  late Future<Map<String, int>> _combinedRevenueFuture;

  @override
  void initState() {
    super.initState();
    // Load combined revenue (current orders + historical)
    _combinedRevenueFuture = AnalyticsCalculator.calculateCombinedRevenue(
      widget.allOrders,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _combinedRevenueFuture,
      builder: (context, snapshot) {
        // Gunakan combined revenue jika tersedia, jika tidak gunakan hanya current
        final revenue =
            snapshot.data ??
            AnalyticsCalculator.calculateRevenue(widget.allOrders);
        final totalStock = widget.menuItems.fold(
          0,
          (sum, item) => sum + item.stock,
        );
        final totalMenu = widget.menuItems.length;
        final totalOrders = widget.allOrders.length;
        final paidOrders = widget.allOrders
            .where((o) => o.status == 'paid')
            .length;

        final monthlyRevenue = revenue['month'] ?? 0;
        final yearlyRevenue = revenue['year'] ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "Dashboard Analytics",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Gradient Background
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selamat Datang Admin",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Warung Cak Amin",
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Revenue Section with Combined Data
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "💰 Pendapatan",
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          // Show loading indicator if data is still loading
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          _EnhancedRevenueCard(
                            title: "Hari Ini",
                            amount: revenue['today']!,
                            percentage: monthlyRevenue > 0
                                ? ((revenue['today']! / monthlyRevenue) * 100)
                                : 0,
                            color: Colors.blue,
                            icon: Icons.today,
                          ),
                          _EnhancedRevenueCard(
                            title: "Minggu Ini",
                            amount: revenue['week']!,
                            percentage: monthlyRevenue > 0
                                ? ((revenue['week']! / monthlyRevenue) * 100)
                                : 0,
                            color: Colors.orange,
                            icon: Icons.date_range,
                          ),
                          _EnhancedRevenueCard(
                            title: "Bulan Ini",
                            amount: revenue['month']!,
                            percentage: yearlyRevenue > 0
                                ? ((revenue['month']! / yearlyRevenue) * 100)
                                : 0,
                            color: Colors.green,
                            icon: Icons.calendar_today,
                          ),
                          _EnhancedRevenueCard(
                            title: "Tahun Ini",
                            amount: revenue['year']!,
                            percentage: 100,
                            color: Colors.purple,
                            icon: Icons.event,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Inventory Summary
                      Container(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade400,
                                    Colors.orange.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.analytics,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Ringkasan Inventori",
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: "Total Menu",
                              value: totalMenu.toString(),
                              color: Colors.teal,
                              icon: Icons.restaurant_menu,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              title: "Total Stok",
                              value: totalStock.toString(),
                              color: Colors.indigo,
                              icon: Icons.inventory_2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: "Total Pesanan",
                              value: totalOrders.toString(),
                              color: Colors.amber,
                              icon: Icons.receipt,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              title: "Pesanan Dibayar",
                              value: paidOrders.toString(),
                              color: Colors.lightGreen,
                              icon: Icons.verified,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Top Selling Items
                      Container(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade400,
                                    Colors.amber.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.trending_up,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Menu Populer",
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._getTopSellingItems().asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final totalRevenue = _getTopSellingItems().fold(
                          0,
                          (sum, i) => sum + (i['revenue'] as int),
                        );
                        final percentage = totalRevenue > 0
                            ? ((item['revenue'] as int) / totalRevenue * 100)
                            : 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade50,
                                Colors.orange.shade100.withOpacity(0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.orange.shade300,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.orange.shade400,
                                              Colors.orange.shade600,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.orange.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            (index + 1).toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Colors.grey,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Terjual: ${item['count']} porsi",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.green.shade400,
                                                  Colors.green.shade600,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.green
                                                      .withOpacity(0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              "${percentage.toStringAsFixed(1)}%",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "Rp ${AnalyticsCalculator.formatCurrency(item['revenue'])}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: percentage / 100,
                                      minHeight: 8,
                                      backgroundColor: Colors.orange.shade200,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.orange.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 28),
                      // Low Stock Warning
                      if (_getLowStockItems().isNotEmpty) ...[
                        Text(
                          "⚠️ Stok Menipis",
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                        ),
                        const SizedBox(height: 16),
                        ..._getLowStockItems().map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red[300]!,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.warning_amber,
                                  color: Colors.red,
                                ),
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "Stok tersisa: ${item.stock} porsi",
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          );
                        }).toList(),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Semua stok dalam kondisi baik",
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getTopSellingItems() {
    final Map<String, int> itemSales = {};
    final Map<String, int> itemRevenue = {};

    for (var order in widget.allOrders) {
      if (order.status == 'paid') {
        for (var cartItem in order.items) {
          final itemName = cartItem.menuItem.name;
          itemSales[itemName] = (itemSales[itemName] ?? 0) + cartItem.quantity;
          itemRevenue[itemName] =
              (itemRevenue[itemName] ?? 0) + cartItem.totalPrice;
        }
      }
    }

    final items = itemSales.entries
        .map(
          (e) => {
            'name': e.key,
            'count': e.value,
            'revenue': itemRevenue[e.key] ?? 0,
          },
        )
        .toList();

    items.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return items.take(5).toList();
  }

  List<MenuItem> _getLowStockItems() {
    return widget.menuItems
        .where((item) => item.stock <= 5 && item.stock > 0)
        .toList();
  }
}

// ================= ENHANCED REVENUE CARD WIDGET =================
class _EnhancedRevenueCard extends StatelessWidget {
  final String title;
  final int amount;
  final double percentage;
  final Color color;
  final IconData icon;

  const _EnhancedRevenueCard({
    required this.title,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Rp ${AnalyticsCalculator.formatCurrency(amount)}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${percentage.toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================= SUMMARY CARD WIDGET =================
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // Can add functionality later
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FoodApp extends StatelessWidget {
  const FoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Order App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: const LoginPage(),
    );
  }
}

// ================= LOGIN PAGE =================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  UserRole selectedRole = UserRole.customer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lunch_dining, size: 60, color: Colors.orange),
                  const SizedBox(width: 12),
                  Icon(Icons.local_drink, size: 60, color: Colors.blue),
                  const SizedBox(width: 12),
                  Icon(Icons.dining, size: 60, color: Colors.green),
                  const SizedBox(width: 12),
                  Icon(Icons.flatware, size: 60, color: Colors.red),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "Login",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Pilih Role:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<UserRole>(
                        segments: const [
                          ButtonSegment(
                            label: Text("Admin"),
                            value: UserRole.admin,
                          ),
                          ButtonSegment(
                            label: Text("Kasir"),
                            value: UserRole.cashier,
                          ),
                          ButtonSegment(
                            label: Text("Pelanggan"),
                            value: UserRole.customer,
                          ),
                        ],
                        selected: <UserRole>{selectedRole},
                        onSelectionChanged: (Set<UserRole> newSelection) {
                          setState(() {
                            selectedRole = newSelection.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (selectedRole == UserRole.customer) ...[
                _CustomerLoginForm(
                  onLogin: (name, tableNumber) {
                    _navigateToHome(name, UserRole.customer, tableNumber);
                  },
                ),
              ] else ...[
                _AdminCashierLoginForm(
                  role: selectedRole,
                  onLogin: (name) {
                    _navigateToHome(name, selectedRole, null);
                  },
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHome(String name, UserRole role, int? tableNumber) {
    final user = User(name: name, role: role, tableNumber: tableNumber);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(user: user)),
    );
  }
}

// ================= CUSTOMER LOGIN FORM =================
class _CustomerLoginForm extends StatefulWidget {
  final Function(String, int) onLogin;

  const _CustomerLoginForm({required this.onLogin});

  @override
  State<_CustomerLoginForm> createState() => _CustomerLoginFormState();
}

class _CustomerLoginFormState extends State<_CustomerLoginForm> {
  late TextEditingController nameController;
  late TextEditingController tableController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    tableController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    tableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Pelanggan',
            prefixIcon: Icon(Icons.restaurant_menu),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: tableController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nomor Meja',
            prefixIcon: Icon(Icons.dining),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || tableController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Nama dan Nomor Meja tidak boleh kosong"),
                  ),
                );
                return;
              }
              try {
                final tableNumber = int.parse(tableController.text);
                widget.onLogin(nameController.text, tableNumber);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Nomor Meja harus berupa angka"),
                  ),
                );
              }
            },
            child: const Text("Masuk"),
          ),
        ),
      ],
    );
  }
}

// ================= ADMIN/CASHIER LOGIN FORM =================
class _AdminCashierLoginForm extends StatefulWidget {
  final UserRole role;
  final Function(String) onLogin;

  const _AdminCashierLoginForm({required this.role, required this.onLogin});

  @override
  State<_AdminCashierLoginForm> createState() => _AdminCashierLoginFormState();
}

class _AdminCashierLoginFormState extends State<_AdminCashierLoginForm> {
  late TextEditingController usernameController;
  late TextEditingController passwordController;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.restaurant),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.flatware),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.orange,
              ),
              onPressed: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (usernameController.text.isEmpty ||
                  passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Username dan Password tidak boleh kosong"),
                  ),
                );
                return;
              }

              // Validasi credentials
              final credential = AuthData.validateLogin(
                usernameController.text,
                passwordController.text,
                widget.role,
              );

              if (credential != null) {
                widget.onLogin(credential.displayName);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Username atau Password salah untuk role ${widget.role.name.toUpperCase()}",
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Login"),
          ),
        ),
      ],
    );
  }
}

// ================= HOME PAGE =================
class HomePage extends StatefulWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static late List<MenuItem> menu = [];
  final List<CartItem> cart = [];
  ProductCategory selectedCategory = ProductCategory.makanan;
  String searchQuery = "";
  String _sortBy = 'name'; // name, price, bestSelling, recommended

  // Global state untuk orders (dalam aplikasi real gunakan state management)
  static final List<Order> allOrders = [];

  @override
  void initState() {
    super.initState();
    // Initialize menu dan load data dari storage
    _loadData();
    // Verifikasi data saat aplikasi dimulai
    DataPersistence.verifyStoredData();
  }

  Future<void> _loadData() async {
    try {
      // Load menu items dari storage
      final loadedMenu = await DataPersistence.loadMenuItems();

      if (loadedMenu.isNotEmpty) {
        setState(() {
          menu = loadedMenu;
        });
      } else {
        // Gunakan default menu jika belum ada data tersimpan
        menu = [
          MenuItem(
            id: '1',
            name: 'Burger',
            price: 25000,
            stock: 10,
            category: ProductCategory.makanan,
            imageUrl:
                'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300',
          ),
          MenuItem(
            id: '2',
            name: 'Pizza',
            price: 40000,
            stock: 5,
            category: ProductCategory.makanan,
            imageUrl:
                'https://images.unsplash.com/photo-1604068549290-dea0e4a305ca?w=300',
          ),
          MenuItem(
            id: '3',
            name: 'Nasi Goreng',
            price: 20000,
            stock: 0,
            category: ProductCategory.makanan,
            imageUrl:
                'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300',
          ),
          MenuItem(
            id: '4',
            name: 'Es Teh',
            price: 5000,
            stock: 20,
            category: ProductCategory.minuman,
            imageUrl:
                'https://images.unsplash.com/photo-1544434278519-f9d50aafb6cf?w=300',
          ),
          MenuItem(
            id: '5',
            name: 'Kopi',
            price: 10000,
            stock: 15,
            category: ProductCategory.minuman,
            imageUrl:
                'https://images.unsplash.com/photo-1559056199-641a0ac8b3f7?w=300',
          ),
          MenuItem(
            id: '6',
            name: 'Gorengan',
            price: 8000,
            stock: 30,
            category: ProductCategory.snack,
            imageUrl:
                'https://images.unsplash.com/photo-1574080867614-e4c56dc1e127?w=300',
          ),
          MenuItem(
            id: '7',
            name: 'Kue',
            price: 12000,
            stock: 25,
            category: ProductCategory.snack,
            imageUrl:
                'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=300',
          ),
        ];
        // Simpan default menu
        await DataPersistence.saveMenuItems(menu);
      }

      // Load orders dari storage
      final loadedOrders = await DataPersistence.loadOrders();
      setState(() {
        allOrders.clear();
        allOrders.addAll(loadedOrders);
      });
    } catch (e) {
      print('✗ Error saat loading data: $e');
    }
  }

  Future<void> _saveMenuData() async {
    await DataPersistence.saveMenuItems(menu);
  }

  Future<void> _saveOrderData() async {
    await DataPersistence.saveOrders(allOrders);
  }

  void _showQuantityInputDialog(
    BuildContext context,
    MenuItem item,
    CartItem cartItem,
  ) {
    final quantityController = TextEditingController(
      text: cartItem.quantity > 0 ? cartItem.quantity.toString() : '1',
    );
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(item.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Stok Tersedia: ${item.stock}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Pesanan',
                      border: const OutlineInputBorder(),
                      errorText: errorMessage,
                      prefixIcon: const Icon(Icons.shopping_bag),
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final quantity = int.tryParse(quantityController.text);

                    if (quantity == null || quantity <= 0) {
                      setStateDialog(() {
                        errorMessage = 'Jumlah harus lebih dari 0';
                      });
                      return;
                    }

                    if (quantity > item.stock) {
                      setStateDialog(() {
                        errorMessage =
                            'Stok tidak cukup! Maksimal: ${item.stock}';
                      });
                      // Show snackbar notification
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '❌ Pesanan berlebih! ${item.name} hanya tersedia ${item.stock} porsi. Anda meminta $quantity porsi.',
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      if (cartItem.quantity > 0) {
                        cartItem.quantity = quantity;
                      } else {
                        cart.add(CartItem(menuItem: item, quantity: quantity));
                      }
                    });

                    Navigator.pop(context);

                    // Show success notification
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ ${item.name} x$quantity ditambahkan ke keranjang',
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool isAdminOrCashier() {
    return widget.user.role == UserRole.admin ||
        widget.user.role == UserRole.cashier;
  }

  List<MenuItem> getFilteredMenu() {
    return menu.where((item) => item.category == selectedCategory).toList();
  }

  List<MenuItem> getFilteredAndSearchedMenu() {
    var filtered = menu
        .where((item) => item.category == selectedCategory)
        .toList();
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (item) =>
                item.name.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    final salesCount = _getSalesCountByItemId();
    final revenueByItemId = _getRevenueByItemId();

    switch (_sortBy) {
      case 'price':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'bestSelling':
        filtered.sort(
          (a, b) => (salesCount[b.id] ?? 0).compareTo(salesCount[a.id] ?? 0),
        );
        break;
      case 'recommended':
        filtered.sort((a, b) {
          final scoreA = _getRecommendationScore(
            a,
            salesCount,
            revenueByItemId,
          );
          final scoreB = _getRecommendationScore(
            b,
            salesCount,
            revenueByItemId,
          );
          return scoreB.compareTo(scoreA);
        });
        break;
      default:
        filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    return filtered;
  }

  Map<String, int> _getSalesCountByItemId() {
    final Map<String, int> salesCount = {};
    for (var order in allOrders) {
      if (order.status == 'paid') {
        for (var cartItem in order.items) {
          salesCount[cartItem.menuItem.id] =
              (salesCount[cartItem.menuItem.id] ?? 0) + cartItem.quantity;
        }
      }
    }
    return salesCount;
  }

  Map<String, int> _getRevenueByItemId() {
    final Map<String, int> revenueByItemId = {};
    for (var order in allOrders) {
      if (order.status == 'paid') {
        for (var cartItem in order.items) {
          revenueByItemId[cartItem.menuItem.id] =
              (revenueByItemId[cartItem.menuItem.id] ?? 0) +
              cartItem.totalPrice;
        }
      }
    }
    return revenueByItemId;
  }

  double _getRecommendationScore(
    MenuItem item,
    Map<String, int> salesCount,
    Map<String, int> revenueByItemId,
  ) {
    final sales = salesCount[item.id] ?? 0;
    final revenue = revenueByItemId[item.id] ?? 0;
    return sales * 2.0 + revenue / 10000.0;
  }

  void _showCustomerOrderStatus(BuildContext context) {
    // Mendapatkan semua pesanan pelanggan yang sedang aktif
    final customerOrders = _HomePageState.allOrders
        .where((o) => o.customer.name == widget.user.name)
        .toList();

    final pendingOrders = customerOrders
        .where((o) => o.status == 'pending')
        .toList();
    final waitingPaymentOrders = customerOrders
        .where((o) => o.status == 'waiting_payment')
        .toList();
    final paidOrders = customerOrders.where((o) => o.status == 'paid').toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Status Pesanan Anda"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pesanan Pending
              if (pendingOrders.isNotEmpty) ...[
                const Text(
                  "⏳ Pesanan Menunggu Konfirmasi:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...pendingOrders.map(
                  (order) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ID: ${order.id.substring(0, 8)}...",
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${order.items.length} item(s) - Rp ${order.totalPrice}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Status: Kasir sedang memeriksa pesanan Anda",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Pesanan Waiting Payment
              if (waitingPaymentOrders.isNotEmpty) ...[
                const Text(
                  "💳 Pesanan Menunggu Pembayaran:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...waitingPaymentOrders.map(
                  (order) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      border: Border.all(color: Colors.amber),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ID: ${order.id.substring(0, 8)}...",
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${order.items.length} item(s) - Rp ${order.totalPrice}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Status: Silakan melakukan pembayaran",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Pesanan Paid
              if (paidOrders.isNotEmpty) ...[
                const Text(
                  "✓ Pesanan Sudah Dibayar:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...paidOrders.map(
                  (order) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ID: ${order.id.substring(0, 8)}...",
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${order.items.length} item(s) - Rp ${order.totalPrice}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Status: Pesanan sedang disiapkan",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              // Jika tidak ada pesanan
              if (customerOrders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Anda belum memiliki pesanan",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _editMenuItem(int index) {
    final item = menu[index];
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    final stockController = TextEditingController(text: item.stock.toString());
    final imageUrlController = TextEditingController(text: item.imageUrl ?? '');
    ProductCategory selectedCat = item.category;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Edit Menu"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stok',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Gambar',
                        border: OutlineInputBorder(),
                        hintText: 'https://example.com/image.jpg',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<ProductCategory>(
                      value: selectedCat,
                      isExpanded: true,
                      items: ProductCategory.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(_getCategoryName(cat)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedCat = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isEmpty ||
                        priceController.text.isEmpty ||
                        stockController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Nama, Harga, dan Stok tidak boleh kosong",
                          ),
                        ),
                      );
                      return;
                    }
                    try {
                      setState(() {
                        final updatedItem = menu[index].copyWith(
                          name: nameController.text,
                          price: int.parse(priceController.text),
                          stock: int.parse(stockController.text),
                          category: selectedCat,
                          imageUrl: imageUrlController.text.isNotEmpty
                              ? imageUrlController.text
                              : null,
                        );
                        // Update lastUpdated timestamp
                        menu[index] = MenuItem(
                          id: updatedItem.id,
                          name: updatedItem.name,
                          price: updatedItem.price,
                          stock: updatedItem.stock,
                          category: updatedItem.category,
                          imageUrl: updatedItem.imageUrl,
                          lastUpdated: DateTime.now(),
                        );
                      });
                      Navigator.pop(context);
                      _saveMenuData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Menu berhasil diperbarui dan disimpan",
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Error: Harga dan Stok harus berupa angka. Detail: $e",
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addMenuItem() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final imageUrlController = TextEditingController();
    ProductCategory selectedCat = ProductCategory.makanan;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Tambah Menu"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stok',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Gambar',
                        border: OutlineInputBorder(),
                        hintText: 'https://example.com/image.jpg',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<ProductCategory>(
                      value: selectedCat,
                      isExpanded: true,
                      items: ProductCategory.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(_getCategoryName(cat)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedCat = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isEmpty ||
                        priceController.text.isEmpty ||
                        stockController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Semua field tidak boleh kosong"),
                        ),
                      );
                      return;
                    }
                    try {
                      setState(() {
                        menu.add(
                          MenuItem(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            name: nameController.text,
                            price: int.parse(priceController.text),
                            stock: int.parse(stockController.text),
                            category: selectedCat,
                            imageUrl: imageUrlController.text.isNotEmpty
                                ? imageUrlController.text
                                : null,
                            lastUpdated: DateTime.now(),
                          ),
                        );
                      });
                      Navigator.pop(context);
                      _saveMenuData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Menu berhasil ditambahkan dan disimpan",
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Error: Harga dan Stok harus berupa angka. Detail: $e",
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getCategoryName(ProductCategory category) {
    switch (category) {
      case ProductCategory.makanan:
        return 'Makanan';
      case ProductCategory.minuman:
        return 'Minuman';
      case ProductCategory.snack:
        return 'Snack';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMenu = getFilteredAndSearchedMenu();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Menu Makanan",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 4,
        shadowColor: Colors.orange.withOpacity(0.3),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          // Kategori filter dengan label yang jelas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: PopupMenuButton<ProductCategory>(
              onSelected: (ProductCategory result) {
                setState(() {
                  selectedCategory = result;
                });
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<ProductCategory>>[
                    PopupMenuItem<ProductCategory>(
                      value: ProductCategory.makanan,
                      child: Row(
                        children: [
                          Icon(
                            Icons.fastfood,
                            color: selectedCategory == ProductCategory.makanan
                                ? Colors.orange
                                : null,
                          ),
                          const SizedBox(width: 8),
                          const Text('Makanan'),
                        ],
                      ),
                    ),
                    PopupMenuItem<ProductCategory>(
                      value: ProductCategory.minuman,
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_drink,
                            color: selectedCategory == ProductCategory.minuman
                                ? Colors.orange
                                : null,
                          ),
                          const SizedBox(width: 8),
                          const Text('Minuman'),
                        ],
                      ),
                    ),
                    PopupMenuItem<ProductCategory>(
                      value: ProductCategory.snack,
                      child: Row(
                        children: [
                          Icon(
                            Icons.rice_bowl,
                            color: selectedCategory == ProductCategory.snack
                                ? Colors.orange
                                : null,
                          ),
                          const SizedBox(width: 8),
                          const Text('Snack'),
                        ],
                      ),
                    ),
                  ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.category, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      _getCategoryName(selectedCategory),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Search icon untuk semua user
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: MenuSearchDelegate(menu),
              ).then((result) {
                if (result != null) {
                  setState(() {
                    searchQuery = result;
                  });
                }
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Chip(
                label: Text(
                  widget.user.role == UserRole.customer
                      ? "${widget.user.name} (Meja ${widget.user.tableNumber})"
                      : "${widget.user.name} (${widget.user.role.name.toUpperCase()})",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: widget.user.role == UserRole.admin
                    ? Colors.red
                    : widget.user.role == UserRole.cashier
                    ? Colors.blue
                    : Colors.green,
              ),
            ),
          ),
          if (widget.user.role == UserRole.cashier)
            Badge(
              label: Text(
                _HomePageState.allOrders
                    .where((o) => o.status == 'pending')
                    .length
                    .toString(),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrdersPage(
                        onOrderConfirmed: () {
                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
              ),
            )
          else if (widget.user.role == UserRole.admin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.inventory_2),
              tooltip: "Admin Menu",
              onSelected: (String result) {
                if (result == 'analytics') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InventoryAnalyticsPage(
                        menuItems: menu,
                        allOrders: allOrders,
                      ),
                    ),
                  );
                } else if (result == 'management') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InventoryManagementPage(
                        menuItems: menu,
                        allOrders: allOrders,
                        onMenuItemsUpdated: (updatedItems) {
                          setState(() {
                            menu = updatedItems;
                          });
                          _saveMenuData();
                        },
                      ),
                    ),
                  );
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'analytics',
                  child: Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.blue),
                      SizedBox(width: 12),
                      Text('Dashboard Analytics'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'management',
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, color: Colors.orange),
                      SizedBox(width: 12),
                      Text('Manajemen Inventori'),
                    ],
                  ),
                ),
              ],
            )
          else
            // Untuk Customer - Tampilkan notifikasi pesanan + cart
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Notifikasi pesanan menunggu pembayaran
                Badge(
                  isLabelVisible: _HomePageState.allOrders
                      .where(
                        (o) =>
                            o.customer.name == widget.user.name &&
                            (o.status == 'waiting_payment' ||
                                o.status == 'pending'),
                      )
                      .isNotEmpty,
                  label: Text(
                    _HomePageState.allOrders
                        .where(
                          (o) =>
                              o.customer.name == widget.user.name &&
                              (o.status == 'waiting_payment' ||
                                  o.status == 'pending'),
                        )
                        .length
                        .toString(),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications),
                    tooltip: "Status Pesanan Anda",
                    onPressed: () {
                      // Tampilkan dialog dengan status pesanan
                      _showCustomerOrderStatus(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Shopping Cart
                IconButton(
                  icon: Badge(
                    label: Text(cart.length.toString()),
                    child: const Icon(Icons.shopping_cart),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutPage(
                          cart: cart,
                          menu: menu,
                          user: widget.user,
                          onOrderPlaced: (order) {
                            setState(() {
                              allOrders.add(order);
                              cart.clear();
                            });
                            _saveOrderData();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            // Search bar untuk semua user
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari menu...',
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.orange,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  const Text(
                    'Urutkan:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        color: Colors.white,
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('Nama')),
                          DropdownMenuItem(
                            value: 'price',
                            child: Text('Termurah - Termahal'),
                          ),
                          DropdownMenuItem(
                            value: 'bestSelling',
                            child: Text('Terlaris'),
                          ),
                          DropdownMenuItem(
                            value: 'recommended',
                            child: Text('Paling Rekomendasi'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sortBy = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredMenu.isEmpty
                  ? Center(
                      child: Text(
                        searchQuery.isNotEmpty
                            ? "Menu '$searchQuery' tidak ditemukan"
                            : "Tidak ada menu ${_getCategoryName(selectedCategory).toLowerCase()}",
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredMenu.length,
                      itemBuilder: (context, index) {
                        final item = filteredMenu[index];
                        final isOutOfStock = item.stock == 0;
                        final cartItem = cart.firstWhere(
                          (ci) => ci.menuItem.id == item.id,
                          orElse: () => CartItem(menuItem: item, quantity: 0),
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          child: Stack(
                            children: [
                              Card(
                                elevation: 8,
                                shadowColor: Colors.orange.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 20.0,
                                        ),
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Rp ${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Action buttons
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (isAdminOrCashier())
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                      size: 20,
                                                    ),
                                                    onPressed: () {
                                                      final menuIndex = menu
                                                          .indexWhere(
                                                            (m) =>
                                                                m.id == item.id,
                                                          );
                                                      if (menuIndex != -1) {
                                                        _editMenuItem(
                                                          menuIndex,
                                                        );
                                                      }
                                                    },
                                                    tooltip: "Edit Menu",
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 40,
                                                          minHeight: 40,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.red
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          return AlertDialog(
                                                            title: const Text(
                                                              "Hapus Menu",
                                                            ),
                                                            content: Text(
                                                              "Apakah Anda yakin ingin menghapus ${item.name}?",
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      "Batal",
                                                                    ),
                                                              ),
                                                              TextButton(
                                                                onPressed: () {
                                                                  setState(() {
                                                                    menu.removeWhere(
                                                                      (m) =>
                                                                          m.id ==
                                                                          item.id,
                                                                    );
                                                                  });
                                                                  Navigator.pop(
                                                                    context,
                                                                  );
                                                                  _saveMenuData();
                                                                  ScaffoldMessenger.of(
                                                                    context,
                                                                  ).showSnackBar(
                                                                    const SnackBar(
                                                                      content: Text(
                                                                        "Menu berhasil dihapus",
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                                child:
                                                                    const Text(
                                                                      "Hapus",
                                                                    ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    },
                                                    tooltip: "Hapus Menu",
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 40,
                                                          minHeight: 40,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          else if (!isOutOfStock)
                                            SizedBox(
                                              height: 40,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (cartItem.quantity > 0)
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.red
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: IconButton(
                                                        icon: const Icon(
                                                          Icons.remove,
                                                          color: Colors.red,
                                                          size: 18,
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            if (cartItem
                                                                    .quantity >
                                                                1) {
                                                              cartItem
                                                                  .quantity--;
                                                            } else {
                                                              cart.removeWhere(
                                                                (ci) =>
                                                                    ci
                                                                        .menuItem
                                                                        .id ==
                                                                    item.id,
                                                              );
                                                            }
                                                          });
                                                        },
                                                        constraints:
                                                            const BoxConstraints(
                                                              minWidth: 40,
                                                              minHeight: 40,
                                                            ),
                                                      ),
                                                    )
                                                  else
                                                    const SizedBox(width: 40),
                                                  if (cartItem.quantity > 0)
                                                    SizedBox(
                                                      width: 35,
                                                      child: Center(
                                                        child: Text(
                                                          cartItem.quantity
                                                              .toString(),
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.add,
                                                        color: Colors.green,
                                                        size: 18,
                                                      ),
                                                      onPressed: () {
                                                        _showQuantityInputDialog(
                                                          context,
                                                          item,
                                                          cartItem,
                                                        );
                                                      },
                                                      constraints:
                                                          const BoxConstraints(
                                                            minWidth: 40,
                                                            minHeight: 40,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          else
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                "Stok Habis",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          if (isAdminOrCashier() &&
                                              !isOutOfStock)
                                            TextButton.icon(
                                              onPressed: () {
                                                final stockController =
                                                    TextEditingController(
                                                      text: item.stock
                                                          .toString(),
                                                    );
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title: const Text(
                                                        "Update Stok",
                                                      ),
                                                      content: TextField(
                                                        controller:
                                                            stockController,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        decoration:
                                                            const InputDecoration(
                                                              labelText: 'Stok',
                                                              border:
                                                                  OutlineInputBorder(),
                                                            ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                              ),
                                                          child: const Text(
                                                            "Batal",
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            try {
                                                              final newStock =
                                                                  int.parse(
                                                                    stockController
                                                                        .text,
                                                                  );
                                                              setState(() {
                                                                final menuIndex =
                                                                    menu.indexWhere(
                                                                      (m) =>
                                                                          m.id ==
                                                                          item.id,
                                                                    );
                                                                if (menuIndex !=
                                                                    -1) {
                                                                  menu[menuIndex] =
                                                                      menu[menuIndex].copyWith(
                                                                        stock:
                                                                            newStock,
                                                                      );
                                                                }
                                                              });
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                              _saveMenuData();
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    "Stok berhasil diperbarui",
                                                                  ),
                                                                ),
                                                              );
                                                            } catch (e) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    "Stok harus berupa angka",
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          },
                                                          child: const Text(
                                                            "Simpan",
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.edit_note,
                                                size: 18,
                                              ),
                                              label: const Text(
                                                "Stok",
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Badge kategori
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getCategoryName(item.category),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              // Badge stok
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOutOfStock
                                        ? Colors.red
                                        : Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isOutOfStock ? "HABIS" : "${item.stock}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: isAdminOrCashier()
          ? FloatingActionButton(
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add),
              onPressed: _addMenuItem,
            )
          : null,
    );
  }
}

// ================= MENU SEARCH DELEGATE =================
class MenuSearchDelegate extends SearchDelegate<String> {
  final List<MenuItem> menu;

  MenuSearchDelegate(this.menu);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = menu
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text("Rp ${item.price}"),
          onTap: () {
            close(context, item.name);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = menu
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final item = suggestions[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text("Rp ${item.price}"),
          onTap: () {
            close(context, item.name);
          },
        );
      },
    );
  }
}

// ================= CHECKOUT PAGE =================
class CheckoutPage extends StatefulWidget {
  final List<CartItem> cart;
  final List<MenuItem> menu;
  final User user;
  final Function(Order)? onOrderPlaced;

  const CheckoutPage({
    super.key,
    required this.cart,
    required this.menu,
    required this.user,
    this.onOrderPlaced,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    notesController = TextEditingController();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int total = widget.cart.fold(0, (sum, item) => sum + item.totalPrice);

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: widget.cart.isEmpty
          ? const Center(child: Text("Keranjang Anda kosong"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final cartItem = widget.cart[index];
                      final item = cartItem.menuItem;

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            "Rp ${item.price} x ${cartItem.quantity} = Rp ${cartItem.totalPrice}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  setState(() {
                                    if (cartItem.quantity > 1) {
                                      cartItem.quantity--;
                                    } else {
                                      widget.cart.removeAt(index);
                                    }
                                  });
                                },
                                iconSize: 18,
                              ),
                              SizedBox(
                                width: 30,
                                child: Center(
                                  child: Text(cartItem.quantity.toString()),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    cartItem.quantity++;
                                  });
                                },
                                iconSize: 18,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    widget.cart.removeAt(index);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Item dihapus dari keranjang",
                                      ),
                                    ),
                                  );
                                },
                                iconSize: 18,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Column(
                    children: [
                      if (widget.user.role == UserRole.customer) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            "Pesanan untuk: ${widget.user.name} (Meja ${widget.user.tableNumber})",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Catatan pelanggan
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText:
                                  'Tambahkan catatan untuk pesanan (opsional)\nContoh: "Pesan tanpa pedas", "Cepat-cepat ya"',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                      Text(
                        "Total: Rp ${AnalyticsCalculator.formatCurrency(total)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.cart.isEmpty
                              ? null
                              : () {
                                  // Buat order object dengan catatan
                                  final order = Order(
                                    id: DateTime.now().millisecondsSinceEpoch
                                        .toString(),
                                    customer: widget.user,
                                    items: List.from(widget.cart),
                                    totalPrice: total,
                                    status: 'pending',
                                    notes: notesController.text.trim(),
                                  );

                                  // Panggil callback jika ada
                                  widget.onOrderPlaced?.call(order);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Pesanan berhasil dikirim ke kasir! Menunggu konfirmasi...",
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context);
                                },
                          child: const Text("Kirim Pesanan"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ================= ORDERS PAGE (FOR CASHIER) =================
class OrdersPage extends StatefulWidget {
  final Function? onOrderConfirmed;

  const OrdersPage({super.key, this.onOrderConfirmed});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  Future<void> _saveOrderData() async {
    await DataPersistence.saveOrders(_HomePageState.allOrders);
  }

  Future<void> _saveMenuData() async {
    await DataPersistence.saveMenuItems(_HomePageState.menu);
  }

  /// Validasi stok untuk pesanan
  /// Return: Map dengan keys 'valid' (bool) dan 'message' (String)
  Map<String, dynamic> _validateOrderStock(Order order) {
    final insufficientItems = <String>[];

    for (var cartItem in order.items) {
      final menuItem = _HomePageState.menu.firstWhere(
        (m) => m.id == cartItem.menuItem.id,
        orElse: () => cartItem.menuItem,
      );

      if (menuItem.stock < cartItem.quantity) {
        insufficientItems.add(
          "${menuItem.name}: Stok tersedia ${menuItem.stock}, diminta ${cartItem.quantity}",
        );
      }
    }

    if (insufficientItems.isNotEmpty) {
      return {'valid': false, 'message': insufficientItems.join('\n')};
    }

    return {'valid': true, 'message': ''};
  }

  /// Kurangi stok untuk semua item dalam pesanan
  void _decreaseOrderStock(Order order) {
    for (var cartItem in order.items) {
      final menuItemIndex = _HomePageState.menu.indexWhere(
        (m) => m.id == cartItem.menuItem.id,
      );
      if (menuItemIndex != -1) {
        _HomePageState.menu[menuItemIndex].stock -= cartItem.quantity;
      }
    }
  }

  /// Tampilkan dialog peringatan stok
  void _showStockWarningDialog(
    BuildContext context,
    String message,
    Order order,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ Peringatan Stok"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Stok tidak cukup untuk pesanan ini:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 12),
            const Text(
              "Pesanan tidak dapat dikonfirmasi sampai stok tersedia.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _showConfirmationNotification(BuildContext context, Order order) {
    // Hitung total semua pesanan dari pelanggan yang sama (nama + nomor meja sama)
    final customerOrders = _HomePageState.allOrders
        .where(
          (o) =>
              o.customer.name == order.customer.name &&
              o.customer.tableNumber == order.customer.tableNumber,
        )
        .toList();

    final totalSubtotal = customerOrders.fold(
      0,
      (sum, o) => sum + o.totalPrice,
    );

    // Menampilkan notifikasi bahwa pesanan sudah dikonfirmasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.green,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "✓ Pesanan Dikonfirmasi!",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              "Pesanan ${order.customer.name} (Meja ${order.customer.tableNumber}) menunggu pembayaran",
              style: const TextStyle(fontSize: 12),
            ),
            if (customerOrders.length > 1) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "💰 Total Semua Pesanan: Rp ${AnalyticsCalculator.formatCurrency(totalSubtotal)} (${customerOrders.length} pesanan)",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPaymentConfirmedNotification(BuildContext context, Order order) {
    // Hitung total semua pesanan dari pelanggan yang sama (nama + nomor meja sama)
    final customerOrders = _HomePageState.allOrders
        .where(
          (o) =>
              o.customer.name == order.customer.name &&
              o.customer.tableNumber == order.customer.tableNumber &&
              o.status == 'paid',
        )
        .toList();

    final totalSubtotal = customerOrders.fold(
      0,
      (sum, o) => sum + o.totalPrice,
    );

    // Menampilkan notifikasi bahwa pembayaran sudah dikonfirmasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "✓ Pembayaran Dikonfirmasi!",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              "Pesanan ${order.customer.name} (Meja ${order.customer.tableNumber}) berhasil dibayar - Struk sudah diterbitkan",
              style: const TextStyle(fontSize: 12),
            ),
            if (customerOrders.length > 1) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "💰 Total Pembayaran: Rp ${AnalyticsCalculator.formatCurrency(totalSubtotal)} (${customerOrders.length} pesanan dibayar)",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingOrders = _HomePageState.allOrders
        .where((order) => order.status == 'pending')
        .toList();
    final confirmedOrders = _HomePageState.allOrders
        .where((order) => order.status == 'waiting_payment')
        .toList();
    final paidOrders = _HomePageState.allOrders
        .where((order) => order.status == 'paid')
        .toList();
    final archivedOrders = _HomePageState.allOrders
        .where((order) => order.archived == true)
        .toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Pesanan Pelanggan"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Menunggu Konfirmasi"),
              Tab(text: "Menunggu Pembayaran"),
              Tab(text: "Sudah Dibayar"),
              Tab(text: "Riwayat"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab Pending Orders
            pendingOrders.isEmpty
                ? const Center(
                    child: Text("Tidak ada pesanan menunggu konfirmasi"),
                  )
                : ListView.builder(
                    itemCount: pendingOrders.length,
                    itemBuilder: (context, index) {
                      final order = pendingOrders[index];

                      return Card(
                        margin: const EdgeInsets.all(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.customer.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Meja ${order.customer.tableNumber}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      order.status.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              // Menampilkan catatan jika ada (untuk pending orders)
                              if (order.notes.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    border: Border.all(
                                      color: Colors.amber,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "📝 Catatan Pelanggan:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        order.notes,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              const Text(
                                "Item Pesanan:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...order.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${item.menuItem.name} x${item.quantity}",
                                      ),
                                      Text(
                                        "Rp ${AnalyticsCalculator.formatCurrency(item.totalPrice)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Total:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Rp ${AnalyticsCalculator.formatCurrency(order.totalPrice)}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        // Hapus pesanan jika ditolak
                                        setState(() {
                                          _HomePageState.allOrders.removeWhere(
                                            (o) => o.id == order.id,
                                          );
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("Pesanan ditolak"),
                                          ),
                                        );
                                      },
                                      child: const Text("Tolak"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Validasi stok sebelum konfirmasi
                                        final stockValidation =
                                            _validateOrderStock(order);

                                        if (!stockValidation['valid']) {
                                          // Tampilkan peringatan jika stok tidak cukup
                                          _showStockWarningDialog(
                                            context,
                                            stockValidation['message'],
                                            order,
                                          );
                                          return;
                                        }

                                        // Jika stok cukup, konfirmasi pesanan
                                        setState(() {
                                          final orderIndex = _HomePageState
                                              .allOrders
                                              .indexWhere(
                                                (o) => o.id == order.id,
                                              );
                                          if (orderIndex != -1) {
                                            // Update status order ke waiting_payment (tanpa kurangi stok di sini)
                                            _HomePageState
                                                    .allOrders[orderIndex]
                                                    .status =
                                                'waiting_payment';
                                            _HomePageState
                                                    .allOrders[orderIndex]
                                                    .confirmedTime =
                                                DateTime.now();
                                          }
                                        });
                                        widget.onOrderConfirmed?.call();
                                        _saveOrderData();

                                        // Tampilkan notifikasi untuk kasir
                                        _showConfirmationNotification(
                                          context,
                                          order,
                                        );
                                      },
                                      child: const Text("Konfirmasi Pesanan"),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.receipt),
                                      label: const Text(
                                        "Lihat Nota",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ReceiptPage(order: order),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            // Tab Waiting Payment Orders
            confirmedOrders.isEmpty
                ? const Center(
                    child: Text("Tidak ada pesanan menunggu pembayaran"),
                  )
                : ListView.builder(
                    itemCount: confirmedOrders.length,
                    itemBuilder: (context, index) {
                      final order = confirmedOrders[index];

                      return Card(
                        margin: const EdgeInsets.all(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.customer.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Meja ${order.customer.tableNumber}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "MENUNGGU PEMBAYARAN",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              // Menampilkan catatan jika ada
                              if (order.notes.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    border: Border.all(
                                      color: Colors.amber,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "📝 Catatan Pelanggan:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        order.notes,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              const Text(
                                "Item Pesanan:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...order.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${item.menuItem.name} x${item.quantity}",
                                      ),
                                      Text(
                                        "Rp ${AnalyticsCalculator.formatCurrency(item.totalPrice)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Total:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Rp ${AnalyticsCalculator.formatCurrency(order.totalPrice)}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.receipt),
                                      label: const Text(
                                        "Lihat Nota",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ReceiptPage(order: order),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        // Validasi stok sebelum konfirmasi pembayaran
                                        final stockValidation =
                                            _validateOrderStock(order);

                                        if (!stockValidation['valid']) {
                                          // Tampilkan peringatan jika stok tidak cukup
                                          _showStockWarningDialog(
                                            context,
                                            stockValidation['message'],
                                            order,
                                          );
                                          return;
                                        }

                                        // Jika stok cukup, kurangi stok dan konfirmasi pembayaran
                                        setState(() {
                                          final orderIndex = _HomePageState
                                              .allOrders
                                              .indexWhere(
                                                (o) => o.id == order.id,
                                              );
                                          if (orderIndex != -1) {
                                            // Kurangi stok untuk setiap item dalam order
                                            _decreaseOrderStock(order);

                                            // Update status order ke paid
                                            _HomePageState
                                                    .allOrders[orderIndex]
                                                    .status =
                                                'paid';
                                            _HomePageState
                                                    .allOrders[orderIndex]
                                                    .paymentStatus =
                                                'paid';
                                            _HomePageState
                                                    .allOrders[orderIndex]
                                                    .paymentConfirmedTime =
                                                DateTime.now();
                                          }
                                        });
                                        // CAPTURE REVENUE WHEN PAID
                                        await RevenueHistoryPersistence.recordPaidOrderRevenue(
                                          order,
                                        );
                                        _saveOrderData();
                                        _saveMenuData();

                                        // Tampilkan notifikasi pembayaran dikonfirmasi
                                        _showPaymentConfirmedNotification(
                                          context,
                                          order,
                                        );
                                      },
                                      child: const Text(
                                        "Konfirmasi Pembayaran",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            // Tab Paid Orders
            paidOrders.isEmpty
                ? const Center(
                    child: Text("Tidak ada pesanan yang sudah dibayar"),
                  )
                : ListView.builder(
                    itemCount: paidOrders.length,
                    itemBuilder: (context, index) {
                      final order = paidOrders[index];

                      return Card(
                        margin: const EdgeInsets.all(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.customer.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Meja ${order.customer.tableNumber}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "SUDAH DIBAYAR",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              // Menampilkan catatan jika ada
                              if (order.notes.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    border: Border.all(
                                      color: Colors.amber,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "📝 Catatan Pelanggan:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        order.notes,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              const Text(
                                "Item Pesanan:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...order.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${item.menuItem.name} x${item.quantity}",
                                      ),
                                      Text(
                                        "Rp ${AnalyticsCalculator.formatCurrency(item.totalPrice)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Total:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Rp ${AnalyticsCalculator.formatCurrency(order.totalPrice)}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.receipt),
                                      label: const Text(
                                        "Lihat Nota",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ReceiptPage(order: order),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.archive),
                                      label: const Text(
                                        "Arsipkan",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: () {
                                        // Arsipkan pesanan agar tidak menumpuk di daftar 'sudah dibayar'
                                        setState(() {
                                          final orderIndex = _HomePageState
                                              .allOrders
                                              .indexWhere(
                                                (o) => o.id == order.id,
                                              );
                                          if (orderIndex != -1) {
                                            _HomePageState
                                                    .allOrders[orderIndex]
                                                    .archived =
                                                true;
                                          }
                                        });
                                        _saveOrderData();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Pesanan dipindahkan ke Riwayat',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            // Tab Riwayat (archived)
            archivedOrders.isEmpty
                ? const Center(child: Text("Riwayat pesanan kosong"))
                : ListView.builder(
                    itemCount: archivedOrders.length,
                    itemBuilder: (context, index) {
                      final order = archivedOrders[index];

                      return Card(
                        margin: const EdgeInsets.all(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.customer.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Meja ${order.customer.tableNumber}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "RIWAYAT",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text(
                                "Item Pesanan:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...order.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${item.menuItem.name} x${item.quantity}",
                                      ),
                                      Text(
                                        "Rp ${AnalyticsCalculator.formatCurrency(item.totalPrice)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Total:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Rp ${AnalyticsCalculator.formatCurrency(order.totalPrice)}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.receipt),
                                      label: const Text(
                                        "Lihat Nota",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ReceiptPage(order: order),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.delete_forever),
                                      label: const Text(
                                        "Hapus Permanen",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text(
                                              'Konfirmasi Hapus',
                                            ),
                                            content: const Text(
                                              'Hapus pesanan ini secara permanen dari riwayat?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(c, false),
                                                child: const Text('Batal'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(c, true),
                                                child: const Text('Hapus'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          // CAPTURE REVENUE BEFORE DELETION
                                          if (order.status == 'paid') {
                                            await RevenueHistoryPersistence.recordDeletedOrderRevenue(
                                              order,
                                            );
                                          }
                                          setState(() {
                                            _HomePageState.allOrders
                                                .removeWhere(
                                                  (o) => o.id == order.id,
                                                );
                                          });
                                          _saveOrderData();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Pesanan dihapus permanen',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
