# Panduan Visual - Fitur Manajemen Inventori

## 📋 Alur Penggunaan

```
┌─────────────────────────────────────────────┐
│         LOGIN PAGE (Admin)                   │
│  Username: admin                             │
│  Password: admin                             │
│  Role: Admin                                 │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│      HOME PAGE / MENU PAGE                   │
│                                               │
│  AppBar dengan icon inventory_2              │
│  [📊 | 🔍 | 📦🔻 | 🚪]                      │
│           analytics ├─▶ Dashboard Analytics  │
│  Click ├─▶ 📦 Inventory
│           management ├─▶ INVENTORY PAGE     │
│                                               │
│  📦 Manajemen Inventori ◀──┐                │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│   INVENTORY MANAGEMENT PAGE                  │
│                                               │
│   [🔍 Cari item...]  [✕]                   │
│                                               │
│   Filter: [Semua Kategori ▼]               │
│   Sort: [Nama ▼] [Reset]                   │
│                                               │
│   Menampilkan 5 dari 7 item                 │
│                                               │
│   ┌──────────────────────────────────────┐ │
│   │ 🍔 Burger                  [HABIS] 🔴│ │
│   │ 🍽️ Makanan                         │ │
│   │ Harga: Rp 25.000                    │ │
│   │ Stok: 0                             │ │
│   │ [Edit] [Hapus]                      │ │
│   └──────────────────────────────────────┘ │
│                                               │
│   ┌──────────────────────────────────────┐ │
│   │ 🍕 Pizza                   [RENDAH] │ │
│   │ 🍽️ Makanan                         │ │
│   │ Harga: Rp 40.000                    │ │
│   │ Stok: 2                             │ │
│   │ [Edit] [Hapus]                      │ │
│   └──────────────────────────────────────┘ │
│                                               │
│   ┌──────────────────────────────────────┐ │
│   │ ☕ Kopi                    [OK] 🟢   │ │
│   │ 🥤 Minuman                         │ │
│   │ Harga: Rp 10.000                    │ │
│   │ Stok: 15                            │ │
│   │ [Edit] [Hapus]                      │ │
│   └──────────────────────────────────────┘ │
│                                               │
└─────────────────────────────────────────────┘
       │                          │
       │ Click Card              │ Click Edit
       ▼                          ▼
   [Detail Modal]          [Edit Form Dialog]
```

## 🎨 UI Components

### 1. Search & Filter Bar
```
┌──────────────────────────────────────┐
│  🔍 [Cari item...]               ✕   │
│                                       │
│  [Semua Kategori ▼] [Nama ▼] [Reset]│
│                                       │
│  Menampilkan 5 dari 7 item           │
└──────────────────────────────────────┘
```
- Orange background dengan padding
- Search real-time
- Filter category dropdown
- Sort dropdown
- Reset button untuk clear semua filter

### 2. Inventory Item Card
```
┌────────────────────────────────────────────┐
│                                             │
│ 🍔 Burger                          [OK] 🟢 │
│  🍽️ Makanan                               │
│                                             │
│ Rp 25.000                    📦 Stok: 10   │
│                                             │
│ [Edit] [Hapus]                             │
│                                             │
└────────────────────────────────────────────┘
```

**Status Badge Colors:**
- 🟢 OK: Green (Stok > 5)
- 🟠 RENDAH: Orange (Stok < 5)
- 🔴 HABIS: Red (Stok = 0)

### 3. Detail Modal (Dialog)
```
┌────────────────────────────────────────────┐
│ 🍔 Burger                          [✕]     │  ← Header Orange Gradient
├────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐ │
│  │                                        │ │
│  │        [Burger Image]                 │ │
│  │                                        │ │
│  └──────────────────────────────────────┘ │
│                                             │
│ 🏷️ Kategori           Makanan              │
│ 💰 Harga              Rp 25.000            │
│ 📦 Stok Tersedia      10                   │
│ 🕐 Diperbarui: 14/1/2026 10:30             │
│                                             │
│ ⚠️ [Warning jika habis]                   │
│                                             │
│ [Edit] [Hapus]                             │
│                                             │
└────────────────────────────────────────────┘
```

### 4. Edit Form Dialog
```
┌────────────────────────────────────────────┐
│ Edit Item Inventori                        │
├────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐ │
│  │        [Image Preview]                │ │
│  └──────────────────────────────────────┘ │
│                                             │
│  [🏷️ Nama Item]                           │
│  [Burger              ]                    │
│                                             │
│  [💰 Harga (Rp)]                          │
│  [25000            ]                       │
│                                             │
│  [📦 Stok]                                │
│  [10               ]                       │
│                                             │
│  [🖼️ URL Gambar]                          │
│  [https://example.com/burger.jpg]         │
│                                             │
│  [🏷️ Kategori]                            │
│  [Makanan ▼]                               │
│                                             │
│  [Batal] [Simpan Perubahan]                │
│                                             │
└────────────────────────────────────────────┘
```

### 5. Stock Indicator Widget
```
Low Stock:                  Out of Stock:           Normal:
┌──────────────────┐       ┌──────────────────┐    ┌──────────────────┐
│ 📦 Stok: 2      │       │ 📦 Stok: 0      │    │ 📦 Stok: 15     │
│ Border: Orange   │       │ Border: Red      │    │ Border: Green    │
│ BG: Orange[50]   │       │ BG: Red[50]      │    │ BG: Green[50]    │
└──────────────────┘       └──────────────────┘    └──────────────────┘
```

## 🔄 User Flow Examples

### Scenario 1: Mencari Item dan Melihat Detail
```
1. Admin membuka Manajemen Inventori
2. Admin ketik "Pizza" di search bar
3. Hanya Pizza card yang tampil
4. Admin klik card Pizza
5. Detail modal membuka
   - Tampil nama, kategori, harga, stok, gambar
   - Tombol Edit dan Hapus tersedia
6. Admin klik [✕] untuk tutup
```

### Scenario 2: Edit Item Stok Rendah
```
1. Admin filter kategori "Makanan"
2. Admin lihat Pizza dengan stok 2 (RENDAH)
3. Admin klik [Edit] button
4. Edit form terbuka
5. Admin ubah stok dari 2 menjadi 20
6. Admin klik [Simpan Perubahan]
7. Snackbar: "Item berhasil diperbarui"
8. Card di-refresh dengan stok baru
```

### Scenario 3: Delete Item
```
1. Admin melihat card item yang ingin dihapus
2. Admin klik [Hapus] button
3. Confirmation dialog muncul
4. Admin klik [Hapus] untuk konfirmasi
5. Item dihapus dari list
6. Snackbar: "Item berhasil dihapus"
7. Counter "Menampilkan X dari Y" ter-update
```

## 🎯 Key Features at a Glance

| Feature | Location | Function |
|---------|----------|----------|
| Search | Top Bar | Real-time search by item name |
| Filter Category | Top Bar | Filter by Makanan/Minuman/Snack |
| Sort | Top Bar | Sort by Name/Stock/Price |
| Reset | Top Bar | Clear all filters |
| Refresh | AppBar | Reload data from storage |
| Card Click | Item Card | Open detail modal |
| Edit Button | Card/Modal | Open edit form |
| Delete Button | Card/Modal | Delete item with confirmation |
| Status Badge | Card Header | Visual stock status indicator |
| Stock Indicator | Card Body | Color-coded stock level |

## 📱 Responsive Design

```
Mobile (< 600px)            Tablet (600-1200px)      Desktop (> 1200px)
┌─────────────┐            ┌──────────────────┐    ┌─────────────────────┐
│ [Search]    │            │ [Search] [Filter]│    │ [Search] [Filter...]│
│ [Filter]    │            │ Item Card 1      │    │ Item Card 1  Card 2 │
│             │            │ Item Card 2      │    │ Item Card 3  Card 4 │
│ Item 1      │            │ Item Card 3      │    │ Item Card 5  Card 6 │
│ Item 2      │            │ Item Card 4      │    │ ...                 │
│ Item 3      │            │                  │    │                     │
│ ...         │            │                  │    │                     │
└─────────────┘            └──────────────────┘    └─────────────────────┘
```

## 🎨 Color Palette

```
Primary Color:      #FF9800 (Orange)
├─ Dark: #F57C00
└─ Light: #FFE0B2

Secondary:          #2196F3 (Blue)
Success:            #4CAF50 (Green)
Warning:            #FF9800 (Orange)
Danger:             #F44336 (Red)
Background:         #F5F5F5 (Light Gray)
Surface:            #FFFFFF (White)
Text Primary:       #212121 (Dark Gray)
Text Secondary:     #757575 (Gray)
```

## 📲 AppBar Menu Flow

```
┌─────────────────────────────────────┐
│ HOME PAGE - Admin User              │
│                                      │
│ [🔙] Menu Makanan [🔍] [📦▼] [🚪]  │
│                        │             │
│                 [📊 Analytics]       │
│                 [📦 Inventori]       │
│                        │             │
│                 SELECT => Open Page  │
└─────────────────────────────────────┘
```

---

**Catatan**: Semua warna dan styling dapat disesuaikan melalui file `inventory_management_page.dart`
