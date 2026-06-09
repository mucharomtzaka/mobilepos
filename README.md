# MobilePOS

Aplikasi Point of Sale (POS) mobile offline untuk pelaku UMKM Indonesia.

## Fitur

### 🛒 Kasir & Transaksi
- Pembelian dengan scan barcode produk
- Keranjang belanja interaktif
- Multiple payment method (Tunai, QRIS, Debit, Kredit)
- Struk digital & thermal printer Bluetooth

### 📦 Produk & Inventori
- Kelola produk (tambah, edit, hapus)
- Kategori produk
- Stock/opname inventori
- Barcode support

### 👥 Pelanggan
- Database pelanggan
- Riwayat transaksi per pelanggan

### 💰 Keuangan
- Catatan income/expense
- Laporan keuangan (harian, mingguan, bulanan)
- Export laporan ke Excel

### 👨‍💼 Shift Management
- Kelola shift kasir
- Report per shift

### ⚙️ Pengaturan
- Tema light/dark mode
- Backup/restore database
- Pengaturan printer
- Pengaturan struk
- Pengaturan meja (untuk restoran/cafe)

## Tech Stack

- **Framework**: Flutter 3.10+
- **State Management**: flutter_bloc
- **Database**: SQLite (sqflite)
- **Barcode**: mobile_scanner
- **Bluetooth**: flutter_blue_plus
- **Export**: excel

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run app
flutter run
```

## Struktur Folder

```
lib/
├── core/           # Core utilities, database, bloc
├── features/       # Feature modules
│   ├── auth/
│   ├── cart/
│   ├── cashier/
│   ├── cashflow/
│   ├── customer/
│   ├── onboarding/
│   ├── payment/
│   ├── product/
│   ├── report/
│   ├── settings/
│   └── shift/
└── main.dart
```

## Lisensi

MIT License