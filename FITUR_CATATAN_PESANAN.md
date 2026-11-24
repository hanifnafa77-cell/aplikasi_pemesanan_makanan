# Fitur Catatan Pesanan Pelanggan

## 📝 Deskripsi
Fitur ini memungkinkan pelanggan untuk menambahkan catatan/pesan khusus saat melakukan checkout pesanan. Kasir dapat membaca catatan ini saat menerima pesanan, sehingga dapat memastikan pesanan disiapkan sesuai dengan keinginan pelanggan.

## ✨ Fitur-Fitur

### 1. Input Catatan di Halaman Checkout
- **Lokasi**: Halaman CheckoutPage (saat pelanggan melakukan checkout)
- **Tampilan**: TextField berwarna orange dengan border
- **Isi**: Pelanggan dapat menambahkan catatan maksimal dalam format text
- **Contoh**: "Pesan tanpa pedas", "Cepat-cepat ya", "Pakai bumbu banyak"

### 2. Tampilan Catatan untuk Kasir
- **Lokasi**: Halaman OrdersPage (daftar pesanan yang diterima kasir)
- **Tab Pending Orders**: Menampilkan catatan pelanggan dalam box amber
- **Tab Confirmed Orders**: Menampilkan catatan pelanggan dalam box amber
- **Format**: Dengan icon 📝 dan tulisan "Catatan Pelanggan:"

### 3. Tampilan Catatan di Struk/Nota
- **Lokasi**: ReceiptPage (halaman nota pemesanan)
- **Posisi**: Sebelum daftar item pesanan
- **Format**: Dengan header "CATATAN PELANGGAN" dalam format teks plaintext

### 4. Catatan Text Dinamis
- **Fitur**: Tombol "Salin Teks" untuk copy catatan ke clipboard
- **Format**: Catatan ditambahkan ke text receipt dengan format terpisah

## 🔄 Alur Kerja

### Untuk Pelanggan (Customer):
1. Pelanggan memilih menu dan menambahkan ke cart
2. Pelanggan klik "Keranjang Belanja" untuk membuka CheckoutPage
3. **BARU**: Di halaman checkout, pelanggan dapat menambahkan catatan di TextField yang disediakan
4. Pelanggan klik "Kirim Pesanan"

### Untuk Kasir (Cashier):
1. Kasir menerima pesanan dari pelanggan
2. **BARU**: Kasir dapat melihat catatan pelanggan dalam box highlight di tengah pesanan
3. Kasir membaca catatan dan memahami keinginan khusus pelanggan
4. Kasir dapat mengkonfirmasi pesanan dengan memperhatikan catatan tersebut

## 📊 Data Structure Changes

### Order Model
```dart
class Order {
  final String id;
  final User customer;
  final List<CartItem> items;
  final int totalPrice;
  final DateTime orderTime;
  String status; // pending, confirmed, paid
  String notes; // ← BARU: Catatan pelanggan
  
  Order({
    // ... existing parameters ...
    this.notes = '', // Default kosong jika tidak ada catatan
  });
}
```

### Data Persistence
- Catatan disimpan dalam SharedPreferences bersama data order lainnya
- Format JSON:
```json
{
  "id": "123456789",
  "customerName": "John Doe",
  "notes": "Pesan tanpa pedas",
  ...
}
```

## 🎨 UI/UX Improvements

### CheckoutPage
- TextField dengan border orange (theme app)
- Placeholder text yang jelas
- Maksimal 3 baris untuk input catatan
- Hanya tampil untuk Customer role

### OrdersPage
- Box highlight berwarna amber [50] dengan border amber
- Icon 📝 untuk visual clarity
- Catatan ditampilkan dalam italic font untuk membedakan dari info lain
- Tampil hanya jika catatan tidak kosong

### ReceiptPage
- Catatan ditampilkan sebelum item pesanan
- Fontsize 12 (sesuai dengan layout receipt lainnya)
- Italic style untuk membedakan

## 🔧 Technical Implementation

### File yang Dimodifikasi
1. **lib/main.dart** - Main application file

### Classes/Functions Modified
1. `Order` - Tambah field `notes`
2. `DataPersistence.saveOrders()` - Save notes ke SharedPreferences
3. `DataPersistence.loadOrders()` - Load notes dari SharedPreferences
4. `_CheckoutPageState` - Tambah TextField untuk input catatan
5. `_OrdersPageState` - Display notes untuk pending dan confirmed orders
6. `ReceiptPage` - Display notes di receipt
7. `_generateReceiptText()` - Include notes dalam text receipt

## ✅ Testing Checklist

- [x] Pelanggan dapat input catatan di checkout
- [x] Catatan tersimpan dengan order
- [x] Kasir dapat melihat catatan di OrdersPage
- [x] Catatan tampil di ReceiptPage
- [x] Catatan tampil di text receipt
- [x] Data persist setelah app restart
- [x] Catatan kosong tidak menampilkan box di OrdersPage
- [x] Syntax error sudah diperbaiki

## 🎯 Future Enhancements

- [ ] Validasi maksimal karakter untuk catatan
- [ ] Kategori catatan predefined (tidak pedas, cepat, dll)
- [ ] Notifikasi khusus untuk catatan urgent
- [ ] Export catatan ke file terpisah
- [ ] Chat real-time antara pelanggan dan kasir
