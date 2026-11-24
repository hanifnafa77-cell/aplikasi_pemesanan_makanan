import 'package:flutter/material.dart';
import '../main.dart';

class InventoryManagementPage extends StatefulWidget {
  final List<MenuItem> menuItems;
  final List<Order> allOrders;
  final Function(List<MenuItem>) onMenuItemsUpdated;

  const InventoryManagementPage({
    super.key,
    required this.menuItems,
    required this.allOrders,
    required this.onMenuItemsUpdated,
  });

  @override
  State<InventoryManagementPage> createState() =>
      _InventoryManagementPageState();
}

class _InventoryManagementPageState extends State<InventoryManagementPage> {
  late List<MenuItem> _menuItems;
  String _searchQuery = '';
  ProductCategory? _filterCategory;
  String _sortBy = 'name'; // name, stock, price

  @override
  void initState() {
    super.initState();
    _menuItems = List.from(widget.menuItems);
  }

  List<MenuItem> _getFilteredAndSortedItems() {
    var filtered = _menuItems.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory =
          _filterCategory == null || item.category == _filterCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    final salesCount = _getSalesCountByItemId();
    final revenueByItemId = _getRevenueByItemId();

    // Sort
    switch (_sortBy) {
      case 'stock':
        filtered.sort((a, b) => a.stock.compareTo(b.stock));
        break;
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
    for (var order in widget.allOrders) {
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
    for (var order in widget.allOrders) {
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

    // Algoritma rekomendasi sederhana:
    // prioritaskan item yang laris terjual dan menghasilkan revenue tinggi.
    return sales * 2.0 + revenue / 10000.0;
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

  IconData _getCategoryIcon(ProductCategory category) {
    switch (category) {
      case ProductCategory.makanan:
        return Icons.fastfood;
      case ProductCategory.minuman:
        return Icons.local_drink;
      case ProductCategory.snack:
        return Icons.rice_bowl;
    }
  }

  void _editMenuItem(MenuItem item) {
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
              title: const Text(
                "Edit Item Inventori",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Preview image
                    if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(item.imageUrl!),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {},
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[200],
                        ),
                        child: const Icon(Icons.image_not_supported),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Item',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.label),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Harga (Rp)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Stok',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.inventory_2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL Gambar',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'https://example.com/image.jpg',
                        prefixIcon: const Icon(Icons.image),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ProductCategory>(
                      value: selectedCat,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.category),
                      ),
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
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
                        final index = _menuItems.indexWhere(
                          (m) => m.id == item.id,
                        );
                        if (index != -1) {
                          _menuItems[index] = MenuItem(
                            id: item.id,
                            name: nameController.text,
                            price: int.parse(priceController.text),
                            stock: int.parse(stockController.text),
                            category: selectedCat,
                            imageUrl: imageUrlController.text.isNotEmpty
                                ? imageUrlController.text
                                : null,
                            lastUpdated: DateTime.now(),
                          );
                        }
                      });

                      widget.onMenuItemsUpdated(_menuItems);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Item berhasil diperbarui"),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                  child: const Text("Simpan Perubahan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteMenuItem(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Hapus Item?"),
          content: Text(
            'Apakah Anda yakin ingin menghapus "${item.name}"? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                setState(() {
                  _menuItems.removeWhere((m) => m.id == item.id);
                });
                widget.onMenuItemsUpdated(_menuItems);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Item berhasil dihapus"),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text("Hapus"),
            ),
          ],
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
              title: const Text(
                "Tambah Menu Baru",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                      ),
                      child: const Icon(Icons.image, size: 60),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Menu',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.label),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Harga (Rp)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Stok',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.inventory_2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL Gambar',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'https://example.com/image.jpg',
                        prefixIcon: const Icon(Icons.image),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ProductCategory>(
                      value: selectedCat,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.category),
                      ),
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
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
                        _menuItems.add(
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

                      widget.onMenuItemsUpdated(_menuItems);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Menu baru berhasil ditambahkan"),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                  child: const Text("Tambahkan Menu"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showItemDetails(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header dengan background color
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.orange.shade700],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(item.imageUrl!),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {},
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[200],
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 60,
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Details
                      _DetailRow(
                        icon: Icons.category,
                        label: 'Kategori',
                        value: _getCategoryName(item.category),
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        icon: Icons.attach_money,
                        label: 'Harga',
                        value:
                            'Rp ${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        icon: Icons.inventory_2,
                        label: 'Stok Tersedia',
                        value: item.stock.toString(),
                        color: item.stock == 0 ? Colors.red : Colors.orange,
                      ),
                      if (item.stock == 0)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Stok habis! Segera restok item ini.',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Diperbarui: ${item.lastUpdated.day}/${item.lastUpdated.month}/${item.lastUpdated.year} ${item.lastUpdated.hour}:${item.lastUpdated.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _editMenuItem(item);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.delete),
                              label: const Text('Hapus'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteMenuItem(item);
                              },
                            ),
                          ),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredAndSortedItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manajemen Inventori',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _menuItems = List.from(widget.menuItems);
              });
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMenuItem,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        tooltip: 'Tambah Menu',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search dan Filter Section
          Container(
            color: Colors.orange.shade50,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Field
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari item...',
                    prefixIcon: const Icon(Icons.search, color: Colors.orange),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.orange,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // Filter dan Sort Row
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Filter Category
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButton<ProductCategory?>(
                                underline: const SizedBox(),
                                value: _filterCategory,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Semua Kategori'),
                                  ),
                                  ...ProductCategory.values.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat,
                                      child: Text(_getCategoryName(cat)),
                                    );
                                  }),
                                ].toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _filterCategory = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Sort
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButton<String>(
                                underline: const SizedBox(),
                                value: _sortBy,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'name',
                                    child: Text('Nama'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'stock',
                                    child: Text('Stok'),
                                  ),
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
                            const SizedBox(width: 8),
                            // Clear Filters Button
                            if (_filterCategory != null ||
                                _searchQuery.isNotEmpty)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.clear, size: 18),
                                label: const Text('Reset'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[400],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _filterCategory = null;
                                    _searchQuery = '';
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Item count
                Text(
                  'Menampilkan ${filteredItems.length} dari ${_menuItems.length} item',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Items List
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _menuItems.isEmpty
                              ? 'Tidak ada item inventori'
                              : 'Item tidak ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredItems.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isLowStock = item.stock < 5;
                      final isOutOfStock = item.stock == 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _InventoryItemCard(
                          item: item,
                          categoryName: _getCategoryName(item.category),
                          categoryIcon: _getCategoryIcon(item.category),
                          isLowStock: isLowStock,
                          isOutOfStock: isOutOfStock,
                          onTap: () => _showItemDetails(item),
                          onEdit: () => _editMenuItem(item),
                          onDelete: () => _deleteMenuItem(item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Widget untuk Detail Row dalam dialog
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

// Widget untuk Inventory Item Card
class _InventoryItemCard extends StatelessWidget {
  final MenuItem item;
  final String categoryName;
  final IconData categoryIcon;
  final bool isLowStock;
  final bool isOutOfStock;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InventoryItemCard({
    required this.item,
    required this.categoryName,
    required this.categoryIcon,
    required this.isLowStock,
    required this.isOutOfStock,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isOutOfStock
                ? Border.all(color: Colors.red, width: 2)
                : isLowStock
                ? Border.all(color: Colors.orange, width: 2)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  categoryIcon,
                                  size: 14,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  categoryName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? Colors.red
                            : isLowStock
                            ? Colors.orange
                            : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOutOfStock
                            ? 'HABIS'
                            : isLowStock
                            ? 'RENDAH'
                            : 'OK',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StockIndicator(stock: item.stock),
                    Text(
                      'Rp ${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                        onPressed: onEdit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Hapus'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget untuk Stock Indicator
class _StockIndicator extends StatelessWidget {
  final int stock;

  const _StockIndicator({required this.stock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: stock == 0
            ? Colors.red[50]
            : stock < 5
            ? Colors.orange[50]
            : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: stock == 0
              ? Colors.red[300]!
              : stock < 5
              ? Colors.orange[300]!
              : Colors.green[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2,
            size: 16,
            color: stock == 0
                ? Colors.red
                : stock < 5
                ? Colors.orange
                : Colors.green,
          ),
          const SizedBox(width: 6),
          Text(
            'Stok: $stock',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: stock == 0
                  ? Colors.red
                  : stock < 5
                  ? Colors.orange
                  : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
