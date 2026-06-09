import 'package:flutter/material.dart';
import 'income_page.dart';
import 'expense_page.dart';
import 'cashflow_page.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  int _index = 0;

  final _pages = const [
    IncomePage(),
    ExpensePage(),
    CashFlowPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          color: Theme.of(context).primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.white,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                );
              }
              return TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              );
            }),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.trending_up), label: 'Pemasukan'),
              NavigationDestination(
                  icon: Icon(Icons.trending_down), label: 'Pengeluaran'),
              NavigationDestination(
                  icon: Icon(Icons.account_balance), label: 'Laporan'),
            ],
          ),
        ),
      ),
    );
  }
}
