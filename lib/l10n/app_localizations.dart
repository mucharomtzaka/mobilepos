import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Drone POS UMKM'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsPrinter.
  ///
  /// In en, this message translates to:
  /// **'Printer'**
  String get settingsPrinter;

  /// No description provided for @settingsPrinterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth printer settings'**
  String get settingsPrinterSubtitle;

  /// No description provided for @settingsReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get settingsReceipt;

  /// No description provided for @settingsReceiptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Store name, address, tax, logo'**
  String get settingsReceiptSubtitle;

  /// No description provided for @settingsTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get settingsTransaction;

  /// No description provided for @settingsTransactionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Auto stock management & cancellation'**
  String get settingsTransactionSubtitle;

  /// No description provided for @settingsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer Management'**
  String get settingsCustomer;

  /// No description provided for @settingsCustomerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add, edit, and delete customers'**
  String get settingsCustomerSubtitle;

  /// No description provided for @settingsTable.
  ///
  /// In en, this message translates to:
  /// **'Table Management'**
  String get settingsTable;

  /// No description provided for @settingsTableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add, edit, and delete restaurant tables'**
  String get settingsTableSubtitle;

  /// No description provided for @settingsCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier Management'**
  String get settingsCashier;

  /// No description provided for @settingsCashierSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add, edit, and delete cashier accounts'**
  String get settingsCashierSubtitle;

  /// No description provided for @settingsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category Management'**
  String get settingsCategory;

  /// No description provided for @settingsCategorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add, edit, and delete product categories'**
  String get settingsCategorySubtitle;

  /// No description provided for @settingsProduct.
  ///
  /// In en, this message translates to:
  /// **'Product Management'**
  String get settingsProduct;

  /// No description provided for @settingsProductSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add, edit, and delete products'**
  String get settingsProductSubtitle;

  /// No description provided for @settingsBundle.
  ///
  /// In en, this message translates to:
  /// **'Bundle Management'**
  String get settingsBundle;

  /// No description provided for @settingsBundleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create product bundles with special prices'**
  String get settingsBundleSubtitle;

  /// No description provided for @settingsStock.
  ///
  /// In en, this message translates to:
  /// **'Stock Management'**
  String get settingsStock;

  /// No description provided for @settingsStockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage product stock'**
  String get settingsStockSubtitle;

  /// No description provided for @settingsShift.
  ///
  /// In en, this message translates to:
  /// **'Shift Management'**
  String get settingsShift;

  /// No description provided for @settingsShiftSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open or close cashier shift'**
  String get settingsShiftSubtitle;

  /// No description provided for @settingsFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance Management'**
  String get settingsFinance;

  /// No description provided for @settingsFinanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Income, expense, and reports'**
  String get settingsFinanceSubtitle;

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get settingsBackup;

  /// No description provided for @settingsBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Backup or restore data'**
  String get settingsBackupSubtitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light, dark, or system'**
  String get settingsThemeSubtitle;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Data collection and usage information'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'DronePos app information'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact Email'**
  String get settingsEmail;

  /// No description provided for @settingsEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'poslitedrone@gmail.com'**
  String get settingsEmailSubtitle;

  /// No description provided for @settingsReport.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get settingsReport;

  /// No description provided for @settingsReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send crash / ANR report to developer'**
  String get settingsReportSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change app language'**
  String get languageSubtitle;

  /// No description provided for @languageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get languageIndonesian;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @cashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get cashier;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @searchProduct.
  ///
  /// In en, this message translates to:
  /// **'Search product...'**
  String get searchProduct;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get saveDraft;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select Customer'**
  String get selectCustomer;

  /// No description provided for @tablePickup.
  ///
  /// In en, this message translates to:
  /// **'Table / Pickup'**
  String get tablePickup;

  /// No description provided for @tableOptional.
  ///
  /// In en, this message translates to:
  /// **'Table (optional)'**
  String get tableOptional;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
