import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomImagePicker {
  static const _channel = MethodChannel('com.umkm.mobilepos/image_picker');

  static Future<String?> pickImage(BuildContext context) async {
    try {
      final images = await _loadImages();
      if (!context.mounted) return null;

      if (images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada gambar ditemukan')),
        );
        return null;
      }

      final selected = await showModalBottomSheet<_GalleryImage>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _GalleryPickerSheet(images: images),
      );
      if (selected == null) return null;

      return await _channel.invokeMethod<String>(
        'copyImageUri',
        {'uri': selected.uri},
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELLED') return null;
      rethrow;
    }
  }

  static Future<List<_GalleryImage>> _loadImages() async {
    final result = await _channel.invokeMethod<List<dynamic>>('listImages');
    return (result ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .map(_GalleryImage.fromMap)
        .toList();
  }
}

class _GalleryImage {
  final String uri;
  final String name;
  final Uint8List thumbnail;

  const _GalleryImage({
    required this.uri,
    required this.name,
    required this.thumbnail,
  });

  factory _GalleryImage.fromMap(Map<dynamic, dynamic> map) {
    return _GalleryImage(
      uri: map['uri'] as String,
      name: (map['name'] as String?) ?? 'Gambar',
      thumbnail: map['thumbnail'] as Uint8List,
    );
  }
}

class _GalleryPickerSheet extends StatelessWidget {
  final List<_GalleryImage> images;

  const _GalleryPickerSheet({required this.images});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pilih Gambar',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final image = images[index];
                  return InkWell(
                    onTap: () => Navigator.pop(context, image),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        image.thumbnail,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
