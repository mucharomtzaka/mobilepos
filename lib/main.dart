import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/database/user_dao.dart';
import 'core/database/shift_dao.dart';
import 'core/database/settings_dao.dart';
import 'core/database/order_dao.dart';
import 'core/database/product_dao.dart';
import 'core/database/customer_dao.dart';
import 'core/bloc/theme_bloc.dart';
import 'core/bloc/locale_bloc.dart';
import 'l10n/app_localizations.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/cart/bloc/cart_bloc.dart';
import 'features/shift/bloc/shift_bloc.dart';
import 'features/auth/ui/login_page.dart';
import 'features/auth/ui/register_page.dart';
import 'features/home_page.dart';
import 'features/product/ui/category_page.dart';
import 'features/onboarding/ui/app_entry.dart';
import 'features/settings/ui/theme_page.dart';

import 'core/utils/bluetooth_printer.dart';
import 'core/utils/receipt_settings.dart';
import 'core/utils/crash_reporter.dart';

bool _isTablet() {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final size = view.physicalSize;
  final ratio = view.devicePixelRatio;
  final shortest = size.shortestSide / ratio;
  return shortest >= 600;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_isTablet()) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Run async tasks in parallel but don't block splash
  Future.wait([
    BluetoothPrinter.loadSaved(),
    ReceiptSettings.load(),
    CrashReporter.init(),
  ]);
  
  runApp(const MobilePosApp());
}

class MobilePosApp extends StatefulWidget {
  const MobilePosApp({super.key});

  @override
  State<MobilePosApp> createState() => _MobilePosAppState();
}

class _MobilePosAppState extends State<MobilePosApp> {
  final _settingsDao = SettingsDao();
  late final ThemeBloc _themeBloc;
  late final LocaleBloc _localeBloc;

  @override
  void initState() {
    super.initState();
    _themeBloc = ThemeBloc(_settingsDao)..add(ThemeLoadRequested());
    _localeBloc = LocaleBloc(_settingsDao)..load();
  }

  @override
  void dispose() {
    _themeBloc.close();
    _localeBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(UserDao())..add(AuthCheckRequested())),
        BlocProvider(create: (_) => CartBloc(OrderDao(), ProductDao(), CustomerDao())),
        BlocProvider(create: (_) => ShiftBloc(ShiftDao())),
        BlocProvider.value(value: _themeBloc),
        BlocProvider.value(value: _localeBloc),
      ],
      child: BlocBuilder<ThemeBloc, ThemeMode>(
        builder: (ctx, themeMode) {
          return BlocBuilder<LocaleBloc, Locale>(
            builder: (ctx, locale) {
              return MaterialApp(
                title: 'Drone POS UMKM',
                debugShowCheckedModeBanner: false,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                themeMode: themeMode,
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                  textTheme: GoogleFonts.poppinsTextTheme(),
                  inputDecorationTheme: const InputDecorationTheme(
                    border: OutlineInputBorder(),
                  ),
                  navigationBarTheme: const NavigationBarThemeData(
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  ),
                  iconTheme: IconThemeData(
                    color: ColorScheme.fromSeed(seedColor: Colors.blue).onSurfaceVariant,
                  ),
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.blue,
                    brightness: Brightness.dark,
                  ),
                  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
                  inputDecorationTheme: const InputDecorationTheme(
                    border: OutlineInputBorder(),
                  ),
                  iconTheme: IconThemeData(
                    color: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark).onSurfaceVariant,
                  ),
                  navigationBarTheme: const NavigationBarThemeData(
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark).primaryContainer,
                      foregroundColor: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark).onPrimaryContainer,
                    ),
                  ),
                  filledButtonTheme: FilledButtonThemeData(
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark).primary,
                      foregroundColor: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark).onPrimary,
                    ),
                  ),
                ),
                home: const AppEntry(),
                routes: {
                  '/home': (_) => const HomePage(),
                  '/login': (_) => const LoginPage(),
                  '/register': (_) => const RegisterPage(),
                  '/categories': (_) => const CategoryPage(),
                  '/theme': (_) => const ThemePage(),
                },
              );
            },
          );
        },
      ),
    );
  }
}
