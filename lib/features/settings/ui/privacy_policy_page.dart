import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kebijakan Privasi')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),
          const _Section(
            title: 'Pengumpulan Data',
            body:
                'Aplikasi DronePos UMKM mengumpulkan data yang diperlukan untuk '
                'operasional kasir, termasuk:\n\n'
                '• Nama dan informasi usaha\n'
                '• Data produk, harga, dan stok\n'
                '• Data transaksi penjualan\n'
                '• Data pelanggan\n'
                '• Informasi akun pengguna (nama, username, peran)',
          ),
          const _Section(
            title: 'Penyimpanan Data',
            body:
                'Semua data disimpan secara lokal di perangkat Anda menggunakan '
                'database SQLite. Tidak ada data yang dikirimkan ke server eksternal '
                'tanpa persetujuan eksplisit dari Anda.',
          ),
          const _Section(
            title: 'Izin Perangkat',
            body:
                'Aplikasi memerlukan beberapa izin perangkat untuk berfungsi '
                'secara optimal:\n\n'
                '• Kamera: Untuk memindai barcode produk dan mengambil foto produk\n'
                '• Penyimpanan: Untuk menyimpan dan memilih gambar produk serta logo struk\n'
                '• Bluetooth: Untuk mencetak struk ke printer Bluetooth\n'
                '• Lokasi: Diperlukan untuk pemindaian perangkat Bluetooth',
          ),
          const _Section(
            title: 'Penggunaan Data',
            body:
                'Data yang dikumpulkan hanya digunakan untuk:\n\n'
                '• Mencatat dan mengelola transaksi penjualan\n'
                '• Mengelola produk, stok, dan inventaris\n'
                '• Mencetak struk dan laporan\n'
                '• Mengelola pelanggan dan keuangan usaha\n'
                '• Backup dan restore data',
          ),
          const _Section(
            title: 'Keamanan Data',
            body:
                'Kami melindungi data Anda dengan menyimpannya secara lokal '
                'di perangkat Anda. Tidak ada mekanisme transmisi data otomatis '
                'ke pihak ketiga. Backup data dapat Anda lakukan secara manual '
                'melalui fitur Backup & Restore.',
          ),
          const _Section(
            title: 'Hak Pengguna',
            body:
                'Anda memiliki kendali penuh atas data Anda. Anda dapat:\n\n'
                '• Melihat, mengubah, dan menghapus data kapan saja\n'
                '• Melakukan backup data ke penyimpanan eksternal\n'
                '• Menghapus semua data dengan menghapus aplikasi\n'
                '• Mengelola izin aplikasi melalui pengaturan perangkat',
          ),
          const _Section(
            title: 'Perubahan Kebijakan',
            body:
                'Kebijakan privasi ini dapat diperbarui dari waktu ke waktu. '
                'Perubahan akan diumumkan melalui pembaruan aplikasi. '
                'Dengan terus menggunakan aplikasi setelah perubahan, '
                'Anda menyetujui kebijakan privasi yang diperbarui.',
          ),
          const _Section(
            title: 'Kontak',
            body:
                'Jika Anda memiliki pertanyaan tentang kebijakan privasi ini, '
                'silakan hubungi kami melalui email:\n'
                'poslitedrone@gmail.com',
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Terakhir diperbarui: Juni 2026',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
