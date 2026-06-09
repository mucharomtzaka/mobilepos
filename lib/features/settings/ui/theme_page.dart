import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/settings_dao.dart';
import '../../../core/bloc/theme_bloc.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  final _dao = SettingsDao();
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mode = await _dao.getThemeMode();
    setState(() => _themeMode = mode);
  }

  Future<void> _setTheme(ThemeMode mode) async {
    await _dao.setThemeMode(mode);
    if (mounted) context.read<ThemeBloc>().add(ThemeChanged(mode));
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tema'),
      ),
      body: ListView(
        children: [
          _buildTile(
            mode: ThemeMode.system,
            title: 'Ikuti Sistem',
            subtitle: 'Menggunakan tema sesuai pengaturan perangkat',
            icon: Icons.brightness_auto,
          ),
          _buildTile(
            mode: ThemeMode.light,
            title: 'Terang',
            subtitle: 'Menggunakan tema warna terang',
            icon: Icons.light_mode,
          ),
          _buildTile(
            mode: ThemeMode.dark,
            title: 'Gelap',
            subtitle: 'Menggunakan tema warna gelap',
            icon: Icons.dark_mode,
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required ThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _themeMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : null),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : null)),
      subtitle: Text(subtitle),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
      onTap: () => _setTheme(mode),
    );
  }
}