# Quick Reference - Data Persistence

## Status: ✅ IMPLEMENTED & VERIFIED

Data yang ditambah/diedit oleh Admin dan KSIR **TERJAMIN TERSIMPAN** sekalipun aplikasi di-restart dari `flutter run`.

## 3 Langkah Verifikasi Cepat

### 1. Login & Tambah Menu
```
1. Run: flutter run
2. Login sebagai Admin (admin/admin)
3. Click "Tambah Menu" (FAB)
4. Isi form → Click "Simpan"
5. Lihat snackbar: ✅ "Menu berhasil ditambahkan dan disimpan"
6. Lihat console: ✅ "✓ Menu items berhasil disimpan: 8 items"
```

### 2. Restart Aplikasi
```
1. Press Ctrl+C (stop flutter run)
2. Run: flutter run
3. Login kembali
4. Verifikasi menu yang ditambah masih ada ✅
```

### 3. Edit & Verifikasi
```
1. Click menu yang ditambah → Edit → Ubah harga
2. Click "Simpan" 
3. Lihat snackbar: ✅ "Menu berhasil diperbarui dan disimpan"
4. Lihat console: ✅ "✓ Menu items berhasil disimpan: 8 items"
5. Restart app → Harga berubah tersimpan ✅
```

## Kode Penting

### DataPersistence Methods
```dart
// Simpan menu (return true/false untuk status)
await DataPersistence.saveMenuItems(menu);

// Load menu dari storage
final items = await DataPersistence.loadMenuItems();

// Verifikasi data storage (logging)
await DataPersistence.verifyStoredData();
```

### Di HomePage, Setiap Ada Perubahan:
```dart
setState(() {
  // Modify menu
  menu.add(newItem);
  // or
  menu[index] = updatedItem;
  // or  
  menu.removeWhere((m) => m.id == itemId);
});

// Selalu panggil ini!
_saveMenuData();
```

## Console Output Harusnya Seperti Ini

✅ **Saat App Startup:**
```
✓ Menu items berhasil dimuat: 7 items
✓ Orders berhasil dimuat: 0 items
=== VERIFIKASI DATA STORAGE ===
Menu items tersimpan: Ya
Jumlah menu items: 7
=============================
```

✅ **Saat Edit/Tambah Menu:**
```
✓ Menu items berhasil disimpan: 8 items
```

❌ **Jika Ada Masalah (cari ini di console):**
```
✗ Error saat menyimpan menu items: ...
✗ Error saat memuat menu items: ...
⚠ Data menu tidak ditemukan di storage
```

## Troubleshooting 2 Menit

| Problem | Solution |
|---------|----------|
| Data hilang setelah restart | 1. Check console untuk errors 2. `flutter clean` 3. `flutter run` ulang |
| Snackbar tidak muncul | Mungkin ada error parsing. Check console untuk "✗ Error" |
| Console tidak menampilkan logging | Pastikan tidak ada output filter di terminal |
| SharedPreferences cache | Uninstall app dari emulator & `flutter run` ulang |

## Where to Look

- **Main implementation:** [lib/main.dart Lines 147-318](lib/main.dart#L147) (DataPersistence class)
- **Data loading:** [lib/main.dart Lines 1333-1424](_loadData method)
- **Edit/Add save:** Setiap method panggil `_saveMenuData()`
- **Console logging:** Search "✓" atau "✗" di console

## Key Points

🔑 **Penting Diingat:**
1. Setiap TAMBAH/EDIT/HAPUS harus panggil `_saveMenuData()`
2. `setState()` untuk update UI, `_saveMenuData()` untuk persist
3. SharedPreferences otomatis handle encoding/decoding
4. lastUpdated timestamp otomatis diupdate saat edit
5. Console logging membantu debugging

## API Overview

```dart
// Save & Load Menu
Future<bool> saveMenuItems(List<MenuItem> items)
Future<List<MenuItem>> loadMenuItems()

// Save & Load Orders  
Future<bool> saveOrders(List<Order> orders)
Future<List<Order>> loadOrders()

// Verify & Debug
Future<void> verifyStoredData()
```

---

**Status:** ✅ Data persistence FULLY IMPLEMENTED dengan error handling, logging, dan verification.

Jika ada masalah → Check console → Cari "✗" → Baca error message → Debug dengan info di atas.
