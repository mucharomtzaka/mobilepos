import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/utils/custom_image_picker.dart';

const _kOnboardingKey = 'onboarding_completed';

class OnboardingPage extends StatefulWidget {
  final Widget nextPage;
  const OnboardingPage({super.key, required this.nextPage});

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingKey) ?? false;
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _ctrl = PageController();
  int _page = 0;

  final _slides = const [
    _SlideData(
      icon: Icons.point_of_sale,
      title: 'Drone POS',
      desc: 'Aplikasi Point of Sale offline untuk UMKM.\nCatat transaksi kapan saja, di mana saja.',
    ),
    _SlideData(
      icon: Icons.inventory_2,
      title: 'Kelola Produk & Stok',
      desc: 'Tambah produk, atur kategori,\npantau stok barang secara real-time.',
    ),
    _SlideData(
      icon: Icons.print,
      title: 'Cetak Struk Bluetooth',
      desc: 'Hubungkan printer thermal Bluetooth\nuntuk mencetak struk langsung.',
    ),
    _SlideData(
      icon: Icons.bar_chart,
      title: 'Laporan & Shift',
      desc: 'Lihat laporan penjualan harian,\nkelola shift kasir, dan evaluasi bisnis.',
    ),
    _SlideData(
      icon: Icons.security,
      title: 'Izin Aplikasi',
      desc: 'Izinkan akses kamera untuk scan barcode\ndan penyimpanan untuk upload foto produk.',
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    await Permission.camera.request();
    await CustomImagePicker.requestGalleryPermission();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingKey, true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => widget.nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _done,
                child: const Text('Lewati'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(
                            s.icon,
                            size: 72,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          s.title,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s.desc,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 16, 40, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: _page == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Next / Done button
                  FilledButton(
                    onPressed: () {
                      if (_page == _slides.length - 1) {
                        _done();
                      } else {
                        _ctrl.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                        _page == _slides.length - 1
                            ? 'Mulai'
                            : 'Selanjutnya',
                        style: GoogleFonts.poppins()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String desc;
  const _SlideData({
    required this.icon,
    required this.title,
    required this.desc,
  });
}
