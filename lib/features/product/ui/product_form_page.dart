import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/utils/custom_image_picker.dart';
import '../bloc/product_bloc.dart';
import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../../core/models/product_variant.dart';
import '../../../core/utils/responsive_dialog.dart';
import '../../../core/utils/responsive_page_insets.dart';
import '../../../core/utils/scanner_overlay_painter.dart';

class ProductFormPage extends StatefulWidget {
  final Product? product;
  const ProductFormPage({super.key, this.product});
  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _barcode, _price, _stock, _unit;
  int? _categoryId;
  String? _imagePath;
  final _variants = <ProductVariant>[];
  bool get _isEdit => widget.product != null;

  final _priceFmt = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name);
    _barcode = TextEditingController(text: p?.barcode);
    _price = TextEditingController(
      text: p != null ? _priceFmt.format(p.price.toInt()) : '',
    );
    _stock = TextEditingController(text: p?.stock.toString() ?? '0');
    _unit = TextEditingController(text: p?.unit ?? 'pcs');
    _categoryId = p?.categoryId;
    _imagePath = p?.imagePath;
    _price.addListener(_formatPrice);
    if (p != null) {
      _variants.addAll(p.variants);
    }
  }

  void _formatPrice() {
    final text = _price.text.replaceAll('.', '');
    if (text.isEmpty) return;
    final parsed = int.tryParse(text);
    if (parsed == null) return;
    final formatted = _priceFmt.format(parsed);
    if (_price.text != formatted) {
      _price.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _barcode, _price, _stock, _unit]) c.dispose();
    super.dispose();
  }

  bool _isPickingImage = false;
  final _imagePicker = ImagePicker();

  Future<void> _pickImage(bool fromCamera) async {
    if (_isPickingImage) return;
    _isPickingImage = true;

    try {
      if (fromCamera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                      'Izin kamera ditolak permanen. Izinkan di pengaturan aplikasi.'),
                  action: const SnackBarAction(
                    label: 'Buka Pengaturan',
                    onPressed: openAppSettings,
                  ),
                ),
              );
            }
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin kamera ditolak')),
            );
          }
          return;
        }
        final picked = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 600,
          imageQuality: 80,
        );
        if (picked != null && mounted) {
          final fileName =
              'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedPath = await _copyImageToAppDir(picked.path, fileName);
          setState(() => _imagePath = savedPath ?? picked.path);
        }
      } else {
        final granted = await CustomImagePicker.requestGalleryPermission();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin galeri ditolak')),
            );
          }
          return;
        }
        if (mounted) {
          final path = await CustomImagePicker.pickImage(context);
          if (path != null && mounted) {
            setState(() => _imagePath = path);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    } finally {
      _isPickingImage = false;
    }
  }

  Future<String?> _copyImageToAppDir(String sourcePath, String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final destDir = Directory('${appDir.path}/product_images');
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }
      final destPath = '${destDir.path}/$fileName';
      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (e) {
      return null;
    }
  }

  void _showImageOptions() {
    showConstrainedModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(true); // fromCamera = true
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(false); // fromCamera = false
              },
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Foto',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() => _imagePath = null);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _addVariant() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    showConstrainedDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Varian'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nama Varian',
                    hintText: 'Contoh: Ukuran M, Warna Merah'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Selisih Harga (opsional)', hintText: '0'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Stok Varian (opsional)', hintText: '0'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              setState(() {
                _variants.add(ProductVariant(
                  productId: widget.product?.id ?? 0,
                  name: name,
                  priceAdjustment: double.tryParse(priceCtrl.text) ?? 0,
                  stock: int.tryParse(stockCtrl.text) ?? 0,
                ));
              });
              Navigator.pop(ctx);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _editVariant(int index) {
    final v = _variants[index];
    final nameCtrl = TextEditingController(text: v.name);
    final priceCtrl =
        TextEditingController(text: v.priceAdjustment.toStringAsFixed(0));
    final stockCtrl = TextEditingController(text: v.stock.toString());
    showConstrainedDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Varian'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Varian'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Selisih Harga', hintText: '0'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Stok Varian', hintText: '0'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              setState(() {
                _variants[index] = v.copyWith(
                  name: name,
                  priceAdjustment: double.tryParse(priceCtrl.text) ?? 0,
                  stock: int.tryParse(stockCtrl.text) ?? 0,
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final p = Product(
      id: widget.product?.id,
      categoryId: _categoryId,
      name: _name.text.trim(),
      barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      price: double.parse(_price.text.replaceAll('.', '')),
      stock: int.parse(_stock.text),
      unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
      imagePath: _imagePath,
      isActive: true,
      createdAt: widget.product?.createdAt ?? DateTime.now().toIso8601String(),
    );
    if (_isEdit) {
      context.read<ProductBloc>().add(ProductUpdate(p, variants: _variants));
    } else {
      context.read<ProductBloc>().add(ProductAdd(p, variants: _variants));
    }
    Navigator.pop(context);
  }

  void _delete() {
    showConstrainedDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: const Text('Yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
            onPressed: () {
              context
                  .read<ProductBloc>()
                  .add(ProductDelete(widget.product!.id!));
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProductBloc>().state;
    final categories = state is ProductLoaded
        ? state.categories.toSet().toList()
        : <Category>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk'),
        actions: [
          if (_isEdit)
            IconButton(
                onPressed: _delete,
                icon: const Icon(Icons.delete, color: Colors.red)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: ResponsivePageInsets.content(
            context,
            maxContentWidth: 640,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 80,
          ),
          children: [
            // Image picker
            GestureDetector(
              onTap: _showImageOptions,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                  size: 40, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text('Gambar tidak ditemukan',
                                  style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Tambah Foto Produk',
                              style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              value: categories.any((c) => c.id == _categoryId)
                  ? _categoryId
                  : null,
              decoration: const InputDecoration(
                  labelText: 'Kategori', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('-- Pilih Kategori --')),
                ...categories.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Nama Produk', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _barcode,
                    decoration: const InputDecoration(
                        labelText: 'Barcode (opsional)',
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final code = await _scanBarcode();
                      if (code != null && mounted) {
                        setState(() => _barcode.text = code);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Harga', border: OutlineInputBorder()),
              validator: (v) {
                if (v!.isEmpty) return 'Wajib diisi';
                if (int.tryParse(v.replaceAll('.', '')) == null)
                  return 'Harga tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Stok', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unit,
                    decoration: const InputDecoration(
                        labelText: 'Satuan', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            // Variants section
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Varian Produk',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Varian'),
                  onPressed: _addVariant,
                ),
              ],
            ),
            if (_variants.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                    'Tidak ada varian. Produk akan dijual tanpa varian.',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              ..._variants.asMap().entries.map((e) {
                final v = e.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    dense: true,
                    title: Text(v.name),
                    subtitle: Text(
                        '${v.priceAdjustment > 0 ? '+Rp ${v.priceAdjustment.toStringAsFixed(0)}' : 'Harga dasar'}'
                        '${v.stock > 0 ? ' • Stok: ${v.stock}' : ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _editVariant(e.key),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 18, color: Colors.red),
                          onPressed: () =>
                              setState(() => _variants.removeAt(e.key)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Produk'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _scanBarcode() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Izin kamera ditolak permanen. Izinkan di pengaturan aplikasi.'),
              action: SnackBarAction(
                label: 'Buka Pengaturan',
                onPressed: openAppSettings,
              ),
            ),
          );
        }
        return null;
      }
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin kamera ditolak')),
          );
        }
        return null;
      }
    }

    String? result;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BarcodeScannerPage(
          onDetect: (value) {
            result = value;
            Navigator.pop(context, result);
          },
        ),
      ),
    );
    return result;
  }
}

class _BarcodeScannerPage extends StatefulWidget {
  final void Function(String value) onDetect;
  const _BarcodeScannerPage({required this.onDetect});

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage>
    with SingleTickerProviderStateMixin {
  final _controller = MobileScannerController(useNewCameraSelector: true);
  bool _detected = false;
  late AnimationController _animCtrl;
  late Animation<double> _lineAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _lineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanSize = size.width * 0.75;

    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_detected) return;
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _detected = true;
                widget.onDetect(barcodes.first.rawValue!);
              }
            },
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                        'Gagal mengakses kamera: ${error.errorDetails?.message ?? error.errorCode.name}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _controller.start(),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            },
            placeholderBuilder: (context, child) {
              return const Center(child: CircularProgressIndicator());
            },
          ),
          CustomPaint(
            size: size,
            painter: ScannerOverlayPainter(
              scanRect: Rect.fromCenter(
                center: Offset(size.width / 2, size.height / 2 - 40),
                width: scanSize,
                height: scanSize * 0.5,
              ),
              lineProgress: _lineAnim.value,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.flashlight_on, color: Colors.white),
              onPressed: () => _controller.toggleTorch(),
            ),
          ),
        ],
      ),
    );
  }
}
