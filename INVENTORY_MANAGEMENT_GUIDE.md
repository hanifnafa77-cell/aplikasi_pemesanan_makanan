# Fitur Manajemen Inventori - Dokumentasi

## Overview
Fitur Manajemen Inventori adalah halaman khusus admin untuk mengelola stok barang/menu secara individual dengan UI yang modern, intuitif, dan menarik.

## Fitur Utama

### 1. **Tampilan Item Satu Persatu**
- Setiap item ditampilkan dalam card yang rapi dan informatif
- Card menampilkan:
  - Nama item
  - Kategori dengan icon yang sesuai
  - Status stok (OK, RENDAH, HABIS)
  - Harga
  - Jumlah stok tersedia
  - Tombol aksi (Edit, Hapus)

### 2. **Search dan Filter**
- **Search Bar**: Cari item berdasarkan nama dengan real-time search
- **Filter Kategori**: Tampilkan hanya item dari kategori tertentu (Makanan, Minuman, Snack)
- **Sort/Urutkan**: Urutkan berdasarkan:
  - Nama (alphabetical)
  - Stok (ascending)
  - Harga (ascending)
- **Reset Filter**: Tombol untuk menghapus semua filter sekaligus

### 3. **Item Card Features**
Setiap card item menampilkan:
- **Status Badge**: 
  - 🟢 OK (stok > 5)
  - 🟠 RENDAH (stok < 5)
  - 🔴 HABIS (stok = 0)
- **Stock Indicator**: Visual indicator untuk stok dengan color-coded
- **Action Buttons**:
  - Edit: Membuka form edit untuk mengubah data item
  - Hapus: Menghapus item dari inventori
- **Click Card**: Klik pada card untuk melihat detail lengkap item

### 4. **Detail View Modal**
Ketika mengklik card, akan membuka modal dengan:
- **Header**: Nama item dengan gradient background
- **Image**: Preview gambar dari URL yang tersimpan
- **Detail Information**:
  - Kategori (dengan icon)
  - Harga (dengan formatting Rupiah)
  - Stok tersedia (dengan visual indicator)
  - Waktu terakhir diupdate
- **Warning**: Jika stok habis, tampilkan peringatan merah
- **Action Buttons**: Edit dan Hapus

### 5. **Edit Form**
Form untuk mengedit item dengan:
- Preview image dari URL
- Input field untuk:
  - Nama item
  - Harga (numeric keyboard)
  - Stok (numeric keyboard)
  - URL Gambar
  - Dropdown kategori
- Validasi input (semua field wajib diisi)
- Error handling dengan pesan yang jelas
- Save button yang menyimpan perubahan

### 6. **Statistik dan Summary**
Bagian header menampilkan:
- Total item yang ditampilkan vs total item
- Refresh button untuk update data

### 7. **UI/UX Improvements**
- **Color Scheme**: Orange (primary), Blue (secondary), Green (success), Red (danger)
- **Gradient Backgrounds**: Gradient colors untuk header dialog
- **Icons**: Icon yang sesuai untuk setiap kategori dan action
- **Card Elevation**: Shadow effect pada cards untuk depth
- **Responsive Layout**: Layout yang responsif di berbagai ukuran layar
- **Smooth Animations**: Transisi halus antar state
- **Visual Feedback**: Snackbar notifications untuk feedback user

## Cara Menggunakan

### Mengakses Halaman Manajemen Inventori:
1. Login sebagai Admin
2. Klik icon **inventory_2** di AppBar (sudut kanan atas)
3. Pilih **"Manajemen Inventori"** dari dropdown menu
4. Halaman Manajemen Inventori akan terbuka

### Mencari Item:
1. Gunakan search bar di bagian atas halaman
2. Ketik nama item yang ingin dicari
3. Hasil search akan tampil real-time
4. Klik tombol X untuk clear search

### Filter Item:
1. Klik dropdown **"Semua Kategori"** untuk filter berdasarkan kategori
2. Pilih kategori yang diinginkan
3. Klik dropdown **"Nama"** untuk mengubah urutan sorting

### Melihat Detail Item:
1. Klik pada card item
2. Modal akan terbuka menampilkan:
   - Preview gambar
   - Semua detail item
   - Status stok dengan warning jika habis
3. Klik tombol Edit atau Hapus dari modal ini
4. Atau klik tombol X untuk menutup modal

### Edit Item:
1. Klik tombol Edit pada card atau di detail modal
2. Dialog edit akan terbuka
3. Ubah data yang diperlukan
4. Klik **"Simpan Perubahan"**
5. Akan muncul snackbar konfirmasi

### Menghapus Item:
1. Klik tombol Hapus pada card atau di detail modal
2. Dialog konfirmasi akan muncul
3. Klik **"Hapus"** untuk konfirmasi atau **"Batal"** untuk membatalkan
4. Item akan dihapus dan akan muncul snackbar notifikasi

## Integrasi Sistem

### Data Persistence
- Semua perubahan di halaman Manajemen Inventori otomatis disimpan ke SharedPreferences
- Data yang disimpan:
  - Nama item
  - Harga
  - Stok
  - Kategori
  - URL Gambar
  - Timestamp update terakhir

### Navigation
- Halaman dapat diakses dari AppBar admin dengan dropdown menu
- Dropdown menu admin menampilkan 2 pilihan:
  1. **Dashboard Analytics** - Halaman analytics (yang sudah ada)
  2. **Manajemen Inventori** - Halaman inventori baru

### State Management
- Ketika item diupdate, callback function akan dipanggil
- Data diupdate di HomePage state
- Data otomatis disimpan ke storage

## Technical Details

### File yang Dibuat:
- `lib/pages/inventory_management_page.dart` - Main inventory management page

### File yang Dimodifikasi:
- `lib/main.dart`:
  - Tambah import: `import 'pages/inventory_management_page.dart';`
  - Ubah admin menu dari IconButton menjadi PopupMenuButton
  - Tambah navigation ke InventoryManagementPage

### Classes dan Widgets:
1. **InventoryManagementPage** (StatefulWidget)
   - Main page widget untuk inventory management

2. **_InventoryItemCard** (StatelessWidget)
   - Card widget untuk menampilkan setiap item
   - Properties: isLowStock, isOutOfStock untuk visual indicator

3. **_DetailRow** (StatelessWidget)
   - Reusable widget untuk menampilkan detail info (icon, label, value)

4. **_StockIndicator** (StatelessWidget)
   - Widget untuk menampilkan visual stock indicator

### Warna-warna yang Digunakan:
- Primary: `Colors.orange` (#FF9800)
- Success: `Colors.green` (#4CAF50)
- Warning: `Colors.orange` (#FF9800)
- Error: `Colors.red` (#F44336)
- Info: `Colors.blue` (#2196F3)
- Background: `Colors.grey[50]` (Light gray)

## Future Improvements
Fitur yang dapat ditambahkan di masa depan:
1. Bulk edit untuk multiple items
2. Import/Export inventory data
3. Stock history dan tracking
4. Automatic low stock notifications
5. Barcode scanning untuk quick add/edit
6. Inventory reports dengan charts
7. Stock adjustment reason tracking
8. Multi-level approval untuk delete

## Troubleshooting

### Item tidak muncul setelah diedit?
- Clik tombol Refresh di AppBar
- Restart aplikasi

### Gambar tidak tampil?
- Pastikan URL gambar valid dan accessible
- Gunakan URL HTTPS untuk image

### Error saat edit?
- Pastikan semua field terisi dengan benar
- Harga dan Stok harus berupa angka

---

**Fitur ini dirancang untuk memberikan pengalaman admin yang intuitif, efficient, dan professional dalam mengelola inventori makanan/minuman.**
