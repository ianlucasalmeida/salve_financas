import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeWrapperScreen extends StatelessWidget {
  final Widget child;
  const HomeWrapperScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        // Mantém os 4 itens principais
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined), 
            selectedIcon: Icon(Icons.analytics),
            label: 'Dash'
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined), 
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Extrato'
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner), 
            selectedIcon: Icon(Icons.qr_code),
            label: 'Scanner'
          ),
          // ✅ Botão Atualizado: Juros -> Carteira
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined), 
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Carteira'
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    
    if (location.startsWith('/dash')) return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/scanner')) return 2;
    if (location.startsWith('/wallet')) return 3; // ✅ Rota atualizada para Wallet
    
    return 0; // Padrão
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/dash'); break;
      case 1: context.go('/transactions'); break;
      case 2: context.go('/scanner'); break;
      case 3: context.go('/wallet'); break; // ✅ Redireciona para WalletScreen
    }
  }
}