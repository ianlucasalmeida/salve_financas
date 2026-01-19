import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart'; // Isar global
import 'package:salve_financas/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:salve_financas/features/dashboard/data/models/transaction_model.dart';
import 'package:salve_financas/features/auth/data/models/user_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController controller = DashboardController();
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUserAndSync();
  }

  /// Carrega o usuário logado e sincroniza as cotações
  Future<void> _loadUserAndSync() async {
    // Busca o usuário para garantir o ID de isolamento (pega o último logado ou único local)
    final userData = await isar.userModels.where().findFirst();
    if (userData != null && mounted) {
      setState(() {
        _user = userData;
        controller.featuredCurrency = userData.preferredCurrency;
      });
      controller.refreshQuotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto o usuário não é carregado, impede a leitura de dados errados
    if (_user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.account_circle_outlined, size: 30),
          onPressed: () => context.pushNamed('profile'),
          tooltip: 'Meu Perfil',
        ),
        title: Text('Olá, ${_user!.name.split(' ')[0]}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => context.pushNamed('concierge'),
            tooltip: 'Concierge AI',
          )
        ],
      ),
      body: StreamBuilder<List<TransactionModel>>(
        // ISOLAMENTO TOTAL: Filtra no banco apenas o que pertence ao usuário logado
        stream: isar.transactionModels
            .filter()
            .userIdEqualTo(_user!.id)
            .watch(fireImmediately: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Se a lista estiver vazia (usuário novo), transactions será [] (sem mocks!)
          final transactions = snapshot.data ?? [];
          final double totalBalance = _calculateTotal(transactions);

          return RefreshIndicator(
            onRefresh: () => controller.refreshQuotes(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Patrimônio Real do Usuário
                _buildBalanceCard(totalBalance),
                
                const SizedBox(height: 24),

                // 2. Gráfico de Evolução Filtrado
                _buildHeaderWithLegend("Evolução Financeira", [
                  _legendItem("Saldo", Theme.of(context).colorScheme.primary),
                ]),
                _buildLineChart(transactions),

                const SizedBox(height: 24),

                // 3. Card de Moeda com Seletor (Ativando funcionalidade de moedas)
                _buildFeaturedCurrencyCard(),

                const SizedBox(height: 24),

                // 4. Gráfico de Gastos por Dia
                _buildHeaderWithLegend("Despesas do Mês", [
                  _legendItem("Gasto Diário", Colors.redAccent),
                ]),
                _buildBarChart(transactions),

                const SizedBox(height: 24),

                _buildStatementButton(context),
                
                const SizedBox(height: 100), 
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('transactions'),
        icon: const Icon(Icons.add),
        label: const Text('Novo Lançamento'),
      ),
    );
  }

  // --- COMPONENTES DE INTERFACE ---

  Widget _buildBalanceCard(double total) {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Saldo Consolidado (${_user?.preferredCurrency ?? 'BRL'})", 
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              "R\$ ${total.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 34, 
                fontWeight: FontWeight.bold,
                color: total < 0 ? Colors.redAccent : Theme.of(context).colorScheme.onPrimaryContainer
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCurrencyCard() {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final String fav = _user?.preferredCurrency ?? controller.featuredCurrency; 
        final String price = controller.quotes['${fav}BRL']?['bid'] ?? '...';

        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.trending_up, color: Colors.amber, size: 20)),
            title: Text("Cotação: $fav"),
            subtitle: const Text("Toque para mudar a moeda"),
            trailing: Text(
              "R\$ $price",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
            ),
            onTap: () => _showCurrencyPicker(), // Abre a tela de moedas solicitada
          ),
        );
      }
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['BTC', 'USD', 'EUR', 'BRL', 'ETH'].map((coin) => ListTile(
            title: Text(coin, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: _user?.preferredCurrency == coin ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () async {
              await isar.writeTxn(() async {
                _user!.preferredCurrency = coin;
                await isar.userModels.put(_user!);
              });
              setState(() => controller.featuredCurrency = coin);
              controller.refreshQuotes();
              if (mounted) Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  // --- GRÁFICOS (REAIS E ISOLADOS) ---

  Widget _buildLineChart(List<TransactionModel> txs) {
    if (txs.isEmpty) return _buildEmptyStateChart();
    
    return Container(
      height: 180,
      padding: const EdgeInsets.only(right: 20, top: 10),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _generateSpots(txs),
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 4,
              belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<TransactionModel> txs) {
    final Map<int, double> dailyData = _groupExpensesByDay(txs);
    if (dailyData.isEmpty) return _buildEmptyStateChart();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(dailyData.values.toList()),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: dailyData.entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [BarChartRodData(toY: e.value, color: Colors.redAccent, width: 14, borderRadius: BorderRadius.circular(4))],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyStateChart() {
    return Container(
      height: 180,
      decoration: BoxDecoration(color: Theme.of(context).cardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
      child: const Center(child: Text("Aguardando lançamentos...", style: TextStyle(color: Colors.grey))),
    );
  }

  // --- LÓGICA DE DADOS ---

  double _calculateTotal(List<TransactionModel> txs) {
    return txs.fold(0.0, (sum, item) => item.type == 'income' ? sum + item.value : sum - item.value);
  }

  List<FlSpot> _generateSpots(List<TransactionModel> txs) {
    final sortedTxs = List<TransactionModel>.from(txs)..sort((a, b) => a.date.compareTo(b.date));
    double balance = 0;
    return sortedTxs.asMap().entries.map((e) {
      balance += (e.value.type == 'income' ? e.value.value : -e.value.value);
      return FlSpot(e.key.toDouble(), balance);
    }).toList();
  }

  Map<int, double> _groupExpensesByDay(List<TransactionModel> txs) {
    Map<int, double> groups = {};
    for (var tx in txs) {
      if (tx.type == 'expense') {
        int day = tx.date.day;
        groups[day] = (groups[day] ?? 0) + tx.value;
      }
    }
    return groups;
  }

  double _getMaxY(List<double> values) => values.isEmpty ? 100 : values.reduce((a, b) => a > b ? a : b) * 1.3;

  Widget _buildHeaderWithLegend(String title, List<Widget> legends) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: legends),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildStatementButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.pushNamed('transactions'),
      icon: const Icon(Icons.list_alt),
      label: const Text("Ver Extrato Completo"),
      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    );
  }
}