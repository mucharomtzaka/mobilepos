import 'package:shared_preferences/shared_preferences.dart';

class ReceiptSettings {
  static const _kStoreName = 'receipt_store_name';
  static const _kAddress = 'receipt_address';
  static const _kPhone = 'receipt_phone';
  static const _kHeader = 'receipt_header';
  static const _kFooter = 'receipt_footer';
  static const _kLogoPath = 'receipt_logo_path';
  static const _kTaxPercent = 'receipt_tax_percent';
  static const _kManageStock = 'manage_stock';
  static const _kCashDrawer = 'cash_drawer';

  static String storeName = 'UMKM Store';
  static String address = '';
  static String phone = '';
  static String header = '';
  static String footer = 'Terima kasih telah berbelanja!';
  static String? logoPath;
  static double taxPercent = 0;
  static bool manageStock = true;
  static bool cashDrawer = false;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    storeName = p.getString(_kStoreName) ?? 'UMKM Store';
    address = p.getString(_kAddress) ?? '';
    phone = p.getString(_kPhone) ?? '';
    header = p.getString(_kHeader) ?? '';
    footer = p.getString(_kFooter) ?? 'Terima kasih telah berbelanja!';
    logoPath = p.getString(_kLogoPath);
    taxPercent = p.getDouble(_kTaxPercent) ?? 0;
    manageStock = p.getBool(_kManageStock) ?? true;
    cashDrawer = p.getBool(_kCashDrawer) ?? false;
  }

  static Future<void> save({
    required String storeName,
    required String address,
    required String phone,
    required String header,
    required String footer,
    String? logoPath,
    double taxPercent = 0,
    bool manageStock = true,
    bool cashDrawer = false,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kStoreName, storeName);
    await p.setString(_kAddress, address);
    await p.setString(_kPhone, phone);
    await p.setString(_kHeader, header);
    await p.setString(_kFooter, footer);
    await p.setDouble(_kTaxPercent, taxPercent);
    await p.setBool(_kManageStock, manageStock);
    await p.setBool(_kCashDrawer, cashDrawer);
    if (logoPath != null) {
      await p.setString(_kLogoPath, logoPath);
    } else {
      await p.remove(_kLogoPath);
    }
    ReceiptSettings.storeName = storeName;
    ReceiptSettings.address = address;
    ReceiptSettings.phone = phone;
    ReceiptSettings.header = header;
    ReceiptSettings.footer = footer;
    ReceiptSettings.logoPath = logoPath;
    ReceiptSettings.taxPercent = taxPercent;
    ReceiptSettings.manageStock = manageStock;
    ReceiptSettings.cashDrawer = cashDrawer;
  }
}
