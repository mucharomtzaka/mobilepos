import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../core/utils/bluetooth_printer.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});
  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  List<BluetoothDevice> _devices = [];
  bool _scanning = false;
  String? _connectingId;

  @override
  void initState() {
    super.initState();
    BluetoothPrinter.loadSaved();
    _scan();
  }

  Future<void> _scan() async {
    // Check Bluetooth state first
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Bluetooth Mati'),
            content: const Text('Nyalakan Bluetooth untuk memindai printer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await FlutterBluePlus.turnOn();
                  _scan();
                },
                child: const Text('Nyalakan'),
              ),
            ],
          ),
        );
      }
      return;
    }
    setState(() => _scanning = true);
    try {
      final devices = await BluetoothPrinter.scanDevices();
      if (mounted) setState(() => _devices = devices);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Scan gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _connectingId = device.remoteId.str);
    try {
      await BluetoothPrinter.connect(device);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '✓ Terhubung ke ${device.platformName.isNotEmpty ? device.platformName : device.remoteId.str}'),
          backgroundColor: Colors.green,
        ));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal terhubung: $e')));
      }
    } finally {
      if (mounted) setState(() => _connectingId = null);
    }
  }

  Future<void> _disconnect() async {
    await BluetoothPrinter.disconnect();
    await BluetoothPrinter.clearSaved();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final savedId = BluetoothPrinter.savedDeviceId;
    final savedName = BluetoothPrinter.savedDeviceName;
    final connected = BluetoothPrinter.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
        actions: [
          if (_scanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _scan,
              tooltip: 'Scan Ulang',
            ),
        ],
      ),
      body: ListView(
        children: [
          // Saved / active printer card
          if (savedId != null)
            Card(
              margin: const EdgeInsets.all(16),
              color: connected ? Colors.green[50] : Colors.orange[50],
              child: ListTile(
                leading: Icon(Icons.print,
                    color: connected ? Colors.green : Colors.orange),
                title: Text(savedName ?? savedId,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(connected ? 'Terhubung ✓' : 'Tersimpan (belum terhubung)'),
                trailing: TextButton(
                  onPressed: _disconnect,
                  child: const Text('Hapus',
                      style: TextStyle(color: Colors.red)),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada printer yang dipasangkan.',
                  style: TextStyle(color: Colors.grey)),
            ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Perangkat Tersedia',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),

          if (_devices.isEmpty && !_scanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Tidak ada perangkat ditemukan.\nPastikan Bluetooth aktif dan printer sudah menyala.',
                  style: TextStyle(color: Colors.grey)),
            ),

          ..._devices.map((device) {
            final name = device.platformName.isNotEmpty
                ? device.platformName
                : device.remoteId.str;
            final isSaved = device.remoteId.str == savedId;
            final isConnecting = _connectingId == device.remoteId.str;

            return ListTile(
              leading: Icon(
                Icons.bluetooth,
                color: isSaved && connected ? Colors.green : Colors.blue,
              ),
              title: Text(name),
              subtitle: Text(device.remoteId.str,
                  style: const TextStyle(fontSize: 11)),
              trailing: isConnecting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : isSaved && connected
                      ? const Chip(
                          label: Text('Aktif',
                              style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.zero,
                        )
                      : ElevatedButton(
                          onPressed: () => _connect(device),
                          child: const Text('Pasang'),
                        ),
            );
          }),
        ],
      ),
    );
  }
}
