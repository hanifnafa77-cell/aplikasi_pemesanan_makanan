# Panduan Data Persistence - Aplikasi Pemesanan Makanan

## Deskripsi
Aplikasi ini mengimplementasikan sistem penyimpanan data yang robust untuk memastikan data yang ditambah atau diedit oleh Admin dan KSIR (Kasir) tetap tersimpan dengan baik sekalipun aplikasi dimulai ulang dari `flutter run`.

## Mekanisme Penyimpanan Data

### 1. **SharedPreferences**
Aplikasi menggunakan `SharedPreferences` untuk menyimpan data secara lokal pada perangkat:
- **Menu Items**: Semua menu makanan/minuman/snack disimpan dengan struktur JSON
- **Orders**: Semua pesanan disimpan dengan detail lengkap

### 2. **DataPersistence Class**
Kelas `DataPersistence` di [main.dart](lib/main.dart#L147) menangani semua operasi penyimpanan:

#### Methods:
- `saveMenuItems(List<MenuItem>)` - Menyimpan daftar menu ke storage
- `loadMenuItems()` - Memuat daftar menu dari storage
- `saveOrders(List<Order>)` - Menyimpan pesanan ke storage
- `loadOrders()` - Memuat pesanan dari storage
- `verifyStoredData()` - Memverifikasi dan melakukan logging data yang tersimpan

### 3. **Error Handling & Logging**
Setiap operasi penyimpanan dan pembacaan dilengkapi dengan:
- Try-catch exception handling
- Console logging untuk debugging
- Boolean return value untuk verifikasi keberhasilan
- Detailed error messages

## Alur Data

### Saat Admin/KSIR Menambah Menu:
```
Admin click "Tambah" → Dialog form → Input data → 
setState() update menu list → _saveMenuData() → 
DataPersistence.saveMenuItems() → SharedPreferences.setString() → 
Snackbar success "Menu berhasil ditambahkan dan disimpan"
```

### Saat Admin/KSIR Mengubah Menu:
```
Admin click "Edit" → Dialog form → Modify data → 
setState() update menu item (lastUpdated diupdate ke DateTime.now()) → 
_saveMenuData() → DataPersistence.saveMenuItems() → 
SharedPreferences.setString() → Snackbar success
```

### Saat Admin/KSIR Menghapus Menu:
```
Admin click "Hapus" → Confirmation dialog → 
setState() remove item from menu list → _saveMenuData() → 
DataPersistence.saveMenuItems() → SharedPreferences.setString() → 
Snackbar success "Menu berhasil dihapus"
```

### Saat Aplikasi Dimulai (flutter run):
```
main() → FoodApp → LoginPage → After login → HomePage.initState() →
_loadData() → DataPersistence.loadMenuItems() (dari storage) → 
setState() update menu list → verifyStoredData() (logging) → 
Data ditampilkan di UI
```

## File Konfigurasi

### pubspec.yaml
Dependency yang digunakan:
```yaml
dependencies:
  shared_preferences: ^2.2.2
```

## Struktur Data Storage

### Menu Items (Key: 'menu_items')
```json
[
  {
    "id": "1",
    "name": "Burger",
    "price": 25000,
    "stock": 10,
    "category": "ProductCategory.makanan",
    "imageUrl": "https://...",
    "lastUpdated": "2026-01-13T10:30:00.000Z"
  }
]
```

### Orders (Key: 'orders_data')
```json
[
  {
    "id": "order123",
    "customerName": "Budi",
    "customerRole": "UserRole.customer",
    "tableNumber": 1,
    "totalPrice": 50000,
    "orderTime": "2026-01-13T10:30:00.000Z",
    "status": "pending",
    "itemCount": 2,
    "notes": "Tanpa es"
  }
]
```

## Testing Data Persistence

### Cara Memverifikasi Data Tersimpan:

1. **Edit/Add Menu sebagai Admin**
   - Login sebagai Admin (username: admin, password: admin)
   - Tambah atau edit menu item
   - Verifikasi snackbar menampilkan "...dan disimpan"

2. **Restart Aplikasi**
   - Jalankan `flutter run` atau restart emulator
   - Login kembali sebagai Admin/Customer
   - Verifikasi menu item yang ditambah masih ada

3. **Lihat Console Logging**
   - Console akan menampilkan:
     ```
     ✓ Menu items berhasil disimpan: N items
     === VERIFIKASI DATA STORAGE ===
     Menu items tersimpan: Ya
     Jumlah menu items: N
     ```

## Debug Commands

Untuk melihat console output:
```bash
# Terminal 1: Run aplikasi
flutter run

# Akan melihat output seperti:
# ✓ Menu items berhasil dimuat: 7 items
# === VERIFIKASI DATA STORAGE ===
# Menu items tersimpan: Ya
# Jumlah menu items: 7
# =============================
```

## Troubleshooting

### Data tidak tersimpan setelah app restart?
1. Pastikan `_saveMenuData()` dipanggil setelah setiap operasi
2. Cek console untuk error messages
3. Verifikasi SharedPreferences dapat write/read (permissions)

### Error "lastUpdated parsing error"?
- Data dari storage harus dalam format ISO8601
- Format valid: "2026-01-13T10:30:00.000Z"

### SharedPreferences cache issue?
- Jalankan `flutter clean` dan `flutter run` ulang
- Atau uninstall app dari emulator/device

## Fitur Tambahan

### Timestamp Tracking
Setiap menu item mencatat `lastUpdated` untuk:
- Tracking kapan item terakhir diubah
- Dapat digunakan untuk sorting/filtering

### Verification Method
Method `verifyStoredData()` dipanggil saat app startup untuk:
- Memverifikasi integritas data
- Logging jumlah items yang tersimpan
- Membantu debugging

## Catatan Penting

✅ **Data persistence sudah terimplementasi dengan baik**
- Semua operasi (add/edit/delete) melakukan save ke storage
- Error handling yang robust
- Logging untuk debugging
- Data loading saat app startup

⚠️ **Konsiderasi untuk Production**
- Pertimbangkan migrasi ke database (SQLite/Hive) untuk volume data besar
- Implementasi backup/restore mechanism
- Enkripsi data sensitif jika diperlukan
