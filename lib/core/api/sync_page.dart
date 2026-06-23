import 'package:flutter/material.dart';
import '../utils/responsive_page_insets.dart';
import 'api_service.dart';
import 'sync_service.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});
  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final _sync = SyncService.instance;
  final _api = ApiService.instance;

  bool _loading = true;
  bool _enabled = false;
  String? _statusMsg;
  String _log = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _enabled = await _sync.isEnabled;
    final lastSync = await _sync.lastSyncAt;
    final log = await _sync.lastLog;
    if (lastSync != null) {
      _statusMsg = 'Last sync: ${_fmt(lastSync)}';
    } else if (_api.hasEnvConfig) {
      _statusMsg = 'Ready';
    } else {
      _statusMsg = 'Config not found';
    }
    _log = log ?? '';
    if (mounted) setState(() => _loading = false);
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sync Server')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: ResponsivePageInsets.horizontal(context, maxContentWidth: 620),
              children: [
                SwitchListTile(
                  title: const Text('Sync Server'),
                  subtitle: Text(_enabled ? 'Active' : 'Inactive'),
                  value: _enabled,
                  onChanged: (v) async {
                    await _sync.setEnabled(v);
                    setState(() => _enabled = v);
                    if (v) {
                      setState(() => _statusMsg = 'Syncing...');
                      final ok = await _sync.syncAll();
                      if (mounted) {
                        final log = await _sync.lastLog;
                        setState(() {
                          _statusMsg = ok ? 'Sync OK' : 'Failed: ${_sync.lastError}';
                          _log = log ?? '';
                        });
                      }
                    }
                  },
                ),
                if (_statusMsg != null)
                  ListTile(
                    leading: Icon(Icons.info, color: theme.colorScheme.primary),
                    title: Text(_statusMsg!, style: const TextStyle(fontSize: 14)),
                  ),
                if (_api.hasEnvConfig)
                  ListTile(
                    leading: Icon(Icons.cloud, color: theme.colorScheme.primary),
                    title: Text(_api.envUrl, style: const TextStyle(fontSize: 13)),
                    subtitle: const Text('Server URL (from .env)'),
                  ),
                if (_log.isNotEmpty) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text('Sync Log', style: theme.textTheme.titleSmall),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _log,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
