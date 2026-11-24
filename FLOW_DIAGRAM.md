# Alur Fitur Catatan Pesanan

## 📊 Flowchart Lengkap

```
┌─────────────────────────────────────────────────────────────────┐
│                    CUSTOMER FLOW                                 │
└─────────────────────────────────────────────────────────────────┘

1. MEMILIH MENU
   ┌──────────────────┐
   │  Home Page       │
   │  (Menu List)     │
   │                  │
   │  ✓ Pilih Menu    │
   │  ✓ Tambah Cart   │
   └────────┬─────────┘
            │
            ▼
2. BUKA CHECKOUT
   ┌──────────────────┐
   │  Checkout Page   │◄────── FITUR BARU
   │  (Cart Summary)  │
   │                  │
   │  ✓ Lihat Items   │
   │  ✓ Edit Quantity │
   └────────┬─────────┘
            │
            ▼
3. TAMBAH CATATAN ◄────── FITUR BARU ★
   ┌──────────────────────────────────┐
   │  Input Catatan (Optional)        │
   │  ┌────────────────────────────┐  │
   │  │ TextField:                 │  │
   │  │ "Pesan tanpa pedas"        │  │
   │  │ "Cepat-cepat ya"           │  │
   │  └────────────────────────────┘  │
   │  Button: [Kirim Pesanan]         │
   └────────┬─────────────────────────┘
            │
            ▼
4. KIRIM PESANAN
   ┌──────────────────────────────┐
   │  Order Created               │
   │  id: xxx                     │
   │  notes: "Tanpa pedas"   ◄────── SIMPAN NOTES
   │  status: 'pending'           │
   │  items: [...]                │
   └────────┬──────────────────────┘
            │
            │ (SharedPreferences)
            ▼
        SAVED TO STORAGE
        

┌─────────────────────────────────────────────────────────────────┐
│                    CASHIER FLOW                                  │
└─────────────────────────────────────────────────────────────────┘

1. BUKA ORDERS PAGE
   ┌──────────────────┐
   │  Orders Page     │
   │  (Notification)  │
   │                  │
   │  Badge: 3        │
   └────────┬─────────┘
            │
            ▼
2. LIHAT PENDING ORDERS
   ┌──────────────────────────────────┐
   │  Tab: "Menunggu Konfirmasi"       │
   │  ┌────────────────────────────┐   │
   │  │ Order #1234                │   │
   │  │ Customer: John             │   │
   │  │ Table: 5                   │   │
   │  │ Status: PENDING            │   │
   │  │                            │   │
   │  │ ┌──────────────────────┐   │   │
   │  │ │ 📝 Catatan Pelanggan:│◄──┼── FITUR BARU ★
   │  │ │ "Tanpa pedas"        │   │   │
   │  │ └──────────────────────┘   │   │
   │  │                            │   │
   │  │ Item Pesanan:              │   │
   │  │ - Nasi Goreng x2           │   │
   │  │ - Es Teh x2                │   │
   │  │                            │   │
   │  │ Total: Rp 60.000           │   │
   │  │                            │   │
   │  │ [Tolak] [Konfirmasi]       │   │
   │  │ [Lihat Nota]               │   │
   │  └────────────────────────────┘   │
   │                                    │
   │  ✓ Baca catatan                   │
   │  ✓ Siapkan pesanan sesuai catatan │
   └────────┬───────────────────────────┘
            │
            ▼
3. KONFIRMASI PESANAN
   ┌──────────────────┐
   │  Click Button    │
   │  "Konfirmasi"    │
   │                  │
   │  Order status:   │
   │  'pending'       │
   │      ↓           │
   │  'confirmed'     │
   └────────┬─────────┘
            │
            ▼
4. LIHAT NOTA
   ┌──────────────────────────────────┐
   │  Receipt Page                    │
   │  ┌────────────────────────────┐  │
   │  │ WARUNG CAK AMIN            │  │
   │  │ Aplikasi Pemesanan Makanan │  │
   │  │                            │  │
   │  │ Nama: John                 │  │
   │  │ Meja: 5                    │  │
   │  │                            │  │
   │  │ CATATAN PELANGGAN    ◄─────┼── FITUR BARU
   │  │ Tanpa pedas                │  │
   │  │                            │  │
   │  │ DAFTAR PESANAN:            │  │
   │  │ Nasi Goreng x2  40.000     │  │
   │  │ Es Teh x2       10.000     │  │
   │  │                            │  │
   │  │ TOTAL: 50.000              │  │
   │  └────────────────────────────┘  │
   │                                   │
   │  [Salin Teks] [Cetak]             │
   └───────────────────────────────────┘
            │
            ▼
5. SIAPKAN PESANAN
   ✓ Kasir membaca catatan
   ✓ Siapkan sesuai keinginan
   ✓ Persiapan lebih akurat


┌─────────────────────────────────────────────────────────────────┐
│                   DATA PERSISTENCE                               │
└─────────────────────────────────────────────────────────────────┘

Order Object:
┌─────────────────────────────────┐
│ Order {                         │
│   id: "1234567890"              │
│   customer: User                │
│   items: [CartItem, ...]        │
│   totalPrice: 50000             │
│   status: "pending"             │
│   orderTime: DateTime           │
│   notes: "Tanpa pedas"   ◄─── NEW
│ }                               │
└─────────────────────────────────┘
            │
            │ SharedPreferences
            ▼
┌─────────────────────────────────────────────────┐
│ JSON Format:                                    │
│ {                                              │
│   "id": "1234567890",                          │
│   "customerName": "John",                      │
│   "tableNumber": 5,                            │
│   "totalPrice": 50000,                         │
│   "status": "pending",                         │
│   "orderTime": "2026-01-13T10:30:00.000",     │
│   "notes": "Tanpa pedas"   ◄─── NEW           │
│ }                                              │
└─────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                   KEY FEATURES                                   │
└─────────────────────────────────────────────────────────────────┘

✨ UNTUK PELANGGAN:
  ✓ Input catatan saat checkout
  ✓ Opsional (tidak wajib)
  ✓ Maksimal 3 baris text
  ✓ Contoh placeholder text

📝 UNTUK KASIR:
  ✓ Lihat catatan di OrdersPage
  ✓ Box highlight untuk visual clarity
  ✓ Display di tab pending & confirmed
  ✓ Hanya muncul jika catatan ada

🧾 UNTUK STRUK:
  ✓ Catatan terlihat di nota
  ✓ Section terpisah di receipt
  ✓ Include di text copy
  ✓ Format terpisah dengan items


┌─────────────────────────────────────────────────────────────────┐
│                   INTERAKSI SISTEM                               │
└─────────────────────────────────────────────────────────────────┘

Customer Input    Save              Load              Display
     │            │                 │                   │
     ▼            ▼                 ▼                   ▼
   
TextField    →  Order obj   →   SharedPrefs  →  OrdersPage
(checkout)      (notes)         (JSON)         (box amber)
                    │                             
                    │                             
                    └──────────────→  ReceiptPage
                                     (text)
                                     
Status Flow:
┌──────────┬────────────┬─────────────┐
│ pending  │ confirmed  │ paid        │
│          │            │             │
│ + notes  │ + notes    │ + notes     │
│ display  │ display    │ display     │
└──────────┴────────────┴─────────────┘

All tabs show notes if not empty
```

## 🔄 Sequence Diagram

```
Customer              App                Cashier
   │                  │                    │
   │─ Select Menu ──→  │                    │
   │                  │                    │
   │─ Open Checkout ──→│                    │
   │                  │                    │
   │─ Write Notes ───→ │                    │
   │    (optional)     │                    │
   │                  │                    │
   │─ Send Order ────→ │                    │
   │                  │                    │
   │                  │◄── Notification ── │
   │                  │   (order arrived) │
   │                  │                    │
   │                  │                    │
   │◄─ Waiting ──────  │                    │
   │   (confirmation)  │                    │
   │                  │                    │
   │                  │── View Order Page──→│
   │                  │                    │
   │                  │  ┌─────────────┐  │
   │                  │  │ 📝 Catatan  │  │
   │                  │  │ "No Spicy"  │  │
   │                  │  └─────────────┘  │
   │                  │                    │
   │                  │◄── Prepare ──────  │
   │                  │   (as noted)      │
   │                  │                    │
   │◄─ Confirm ──────  │                    │
   │                  │                    │
   │  Receive Order   │                    │
   │  + Receipt       │                    │
   │  + Notes         │                    │
   │                  │                    │
```

## 📱 UI Layout

### CheckoutPage (Customer Input)
```
┌─────────────────────────────────────────┐
│            CHECKOUT                     │
├─────────────────────────────────────────┤
│ Cart Items:                             │
│ ├─ Nasi Goreng x2 = 40.000            │
│ ├─ Es Teh x2 = 10.000                 │
│                                         │
│ ┌──────────────────────────────────┐   │
│ │ Pesanan untuk: John (Meja 5)     │   │
│ │                                  │   │
│ │ ┌──────────────────────────────┐ │   │ ◄─ BARU
│ │ │ Tambahkan catatan            │ │   │
│ │ │ (opsional)                   │ │   │
│ │ │                              │ │   │
│ │ │ Pesan tanpa pedas            │ │   │
│ │ │ Cepat-cepat ya               │ │   │
│ │ │                              │ │   │
│ │ └──────────────────────────────┘ │   │
│ └──────────────────────────────────┘   │
│                                         │
│ Total: Rp 50.000                       │
│                                         │
│ [Kirim Pesanan]                        │
└─────────────────────────────────────────┘
```

### OrdersPage (Cashier View)
```
┌─────────────────────────────────────────┐
│       PESANAN PELANGGAN                 │
├─────────────────────────────────────────┤
│ Tab: Menunggu Konfirmasi | Sudah Dibayar│
├─────────────────────────────────────────┤
│ Order #1234                             │
│ John | Meja 5 | PENDING                │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │  📝 Catatan Pelanggan:              │ │ ◄─ BARU
│ │  Pesan tanpa pedas                  │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ Item Pesanan:                           │
│  - Nasi Goreng x2                      │
│  - Es Teh x2                           │
│                                         │
│ Total: Rp 50.000                       │
│                                         │
│ [Tolak] [Konfirmasi] [Lihat Nota]      │
└─────────────────────────────────────────┘
```

---

**Legend:**
- ★ = Fitur Baru
- ◄── = User Action
- ──→ = System Action
- ✓ = Completed
