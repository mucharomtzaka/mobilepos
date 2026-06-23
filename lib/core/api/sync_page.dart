import 'package:flutter/material.dart';
import '../database/settings_dao.dart';
import '../utils/responsive_page_insets.dart';
import 'api_service.dart';
import 'sync_service.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});
  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _sync = SyncService.instance;
  final _api = ApiService.instance;
  final _settings = SettingsDao();

  bool _loading = true;
  bool _loggingIn = false;
  bool _showLogin = false;
  String? _statusMsg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final url = await _api.baseUrl;
    _urlCtrl.text = url;
    final token = await _api.token;
    if (token != null && token.isNotEmpty) {
      final lastSync = await _sync.lastSyncAt;
      setState(() {
        _showLogin = false;
        _statusMsg = lastSync != null ? 'Last sync: ${_fmt(lastSync)}' : 'Connected';
      });
    }
    setState(() => _loading = false);
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _saveUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    await _api.setBaseUrl(url);
    setState(() => _showLogin = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server URL saved')),
    );
  }

  Future<void> _login() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (user.isEmpty || pass.isEmpty) return;
    setState(() => _loggingIn = true);
    final ok = await _sync.login(user, pass);
    if (!mounted) return;
    setState(() => _loggingIn = false);
    if (ok) {
      setState(() {
        _showLogin = false;
        _statusMsg = 'Connected';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login success')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${_sync.lastError}')),
      );
    }
  }

  Future<void> _syncNow() async {
    setState(() => _statusMsg = 'Syncing...');
    final ok = await _sync.syncAll();
    if (!mounted) return;
    if (ok) {
      final lastSync = await _sync.lastSyncAt;
      setState(() => _statusMsg = lastSync != null ? 'Last sync: ${_fmt(lastSync)}' : 'Sync OK');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync completed')),
      );
    } else {
      setState(() => _statusMsg = 'Sync failed: ${_sync.lastError}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: ${_sync.lastError}')),
      );
    }
  }

  Future<void> _disconnect() async {
    await _api.clearToken();
    await _settings.set('server_url', '');
    setState(() {
      _showLogin = false;
      _statusMsg = null;
      _urlCtrl.clear();
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

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
                const SizedBox(height: 16),

                // Status
                if (_statusMsg != null || _sync.isSyncing)
                  Card(
                    child: ListTile(
                      leading: _sync.isSyncing
                          ? const SizedBox(
                              width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(_statusMsg?.contains('fail') == true
                              ? Icons.error
                              : Icons.check_circle,
                              color: _statusMsg?.contains('fail') == true
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary),
                      title: Text(_statusMsg ?? ''),
                      subtitle: _sync.isSyncing ? const Text('Please wait...') : null,
                    ),
                  ),
                const SizedBox(height: 16),

                // Server URL
                Text('Server URL', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _urlCtrl,
                  decoration: InputDecoration(
                    hintText: _api.envUrl.isNotEmpty ? _api.envUrl : 'http://192.168.1.100:3000',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _saveUrl,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save URL'),
                ),

                // Login form
                if (_showLogin) ...[
                  const SizedBox(height: 24),
                  Text('Server Login', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loggingIn ? null : _login,
                    icon: _loggingIn
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.login, size: 18),
                    label: const Text('Login to Server'),
                  ),
                ],

                // Sync controls
                if (!_showLogin && _statusMsg != null) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _sync.isSyncing ? null : _syncNow,
                          icon: _sync.isSyncing
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.sync, size: 18),
                          label: Text(_sync.isSyncing ? 'Syncing...' : 'Sync Now'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _disconnect,
                        icon: const Icon(Icons.link_off, size: 18),
                        label: const Text('Disconnect'),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                // Help text
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('How to connect', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Make sure backend server is running\n'
                          '2. Enter server URL (e.g. http://192.168.1.100:3000)\n'
                          '3. Save URL\n'
                          '4. Login with server admin credentials\n'
                          '5. Tap Sync Now to push/pull data',
                          style: TextStyle(fontSize: 13, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
