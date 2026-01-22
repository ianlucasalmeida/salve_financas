import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart'; 
import 'package:salve_financas/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:salve_financas/features/dashboard/data/models/transaction_model.dart';
import 'package:salve_financas/features/auth/data/models/user_model.dart';
import 'package:salve_financas/features/wallet/data/models/wallet_goal_model.dart';

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

  Future<void> _loadUserAndSync() async {
    final userData = await isar.userModels
        .filter()
        .isSessionActiveEqualTo(true)
        .findFirst();

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
        stream: isar.transactionModels
            .filter()
            .userIdEqualTo(_user!.id)
            .watch(fireImmediately: true),
        builder: (context, snapshot) {
          final transactions = snapshot.data ?? [];
          final double totalBalance = _calculateTotal(transactions);

          return RefreshIndicator(
            onRefresh: _loadUserAndSync,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBalanceCard(totalBalance),
                
                const SizedBox(height: 24),

                _buildHeaderWithLegend("Evolução Financeira", [
                  _legendItem("Saldo", Theme.of(context).colorScheme.primary),
                ]),
                _buildLineChart(transactions),

                const SizedBox(height: 24),

                _buildHeaderWithLegend("Despesas do Mês", [
                  _legendItem("Gasto Diário", Colors.redAccent),
                ]),
                _buildBarChart(transactions),

                const SizedBox(height: 24),

                _buildFeaturedCurrencyCard(),

                const SizedBox(height: 32),

                // ✅ Gráfico de Metas (Barras Individuais Coloridas)
                _buildHeaderWithLegend("Desempenho das Metas", [
                  _legendItem("Progresso (%)", Colors.white),
                ]),
                _buildGoalsBarChart(), // <--- Alterado para gráfico de barras coloridas

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

  // --- COMPONENTES ORIGINAIS (SEM ALTERAÇÃO) ---

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
            onTap: () => _showCurrencyPicker(), 
          ),
        );
      }
    );
  }

  // --- GRÁFICOS (AJUSTADOS) ---

  Widget _buildLineChart(List<TransactionModel> txs) {
    if (txs.isEmpty) return _buildEmptyStateChart("Aguardando lançamentos...");
    
    final spots = _generateSpots(txs);
    final double maxVal = spots.isEmpty ? 100 : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final double minVal = spots.isEmpty ? 0 : spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    
    return Container(
      height: 220,
      padding: const EdgeInsets.only(right: 20, top: 20, left: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(20)
      ),
      child: LineChart(
        LineChartData(
          clipData: const FlClipData.all(),
          maxY: maxVal * 1.1,
          minY: minVal < 0 ? minVal * 1.1 : 0,
          
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.black.withOpacity(0.8),
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) => LineTooltipItem(
                "R\$ ${s.y.toStringAsFixed(2)}",
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              )).toList(),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: (maxVal - minVal) / 5 == 0 ? 1 : (maxVal - minVal) / 5,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
            getDrawingVerticalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 4,
              belowBarData: BarAreaData(
                show: true, 
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1)
              ),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<TransactionModel> txs) {
    final Map<int, double> dailyData = _groupExpensesByDay(txs);
    if (dailyData.isEmpty) return _buildEmptyStateChart("Sem despesas registradas.");

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

  // ✅ GRÁFICO DE BARRAS PARA METAS (CADA CAIXINHA COM SUA COLUNA E COR)
  Widget _buildGoalsBarChart() {
    return StreamBuilder<List<WalletGoalModel>>(
      stream: isar.walletGoalModels
          .filter()
          .userIdEqualTo(_user!.id)
          .watch(fireImmediately: true),
      builder: (context, snapshot) {
        final goals = snapshot.data ?? [];
        if (goals.isEmpty) return _buildEmptyStateChart("Crie sua primeira caixinha na aba Carteira");

        // Paleta de cores vibrantes para diferenciar as metas
        final List<Color> goalColors = [
          Colors.cyanAccent,
          Colors.orangeAccent,
          Colors.purpleAccent,
          Colors.greenAccent,
          Colors.pinkAccent,
          Colors.yellowAccent,
        ];

        return Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100, // Porcentagem máxima
              minY: 0,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, _) {
                      int idx = val.toInt();
                      if (idx >= 0 && idx < goals.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            goals[idx].title.length > 5 ? "${goals[idx].title.substring(0, 5)}.." : goals[idx].title, 
                            style: const TextStyle(fontSize: 10, color: Colors.grey)
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              barGroups: goals.asMap().entries.map((e) {
                final double percent = e.value.targetAmount > 0 
                  ? (e.value.currentAmount / e.value.targetAmount * 100) 
                  : 0;
                
                // Cor única para cada barra
                final color = goalColors[e.key % goalColors.length];

                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: percent > 100 ? 100 : percent, 
                      color: color, 
                      width: 18, 
                      borderRadius: BorderRadius.circular(4),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true, 
                        color: Colors.white.withOpacity(0.05), 
                        toY: 100
                      ),
                    )
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateChart(String message) {
    return Container(
      height: 150,
      decoration: BoxDecoration(color: Theme.of(context).cardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
      child: Center(child: Text(message, style: const TextStyle(color: Colors.grey))),
    );
  }

  // --- LÓGICA DE DADOS ---

  double _calculateTotal(List<TransactionModel> txs) {
    return txs.fold(0.0, (sum, item) => item.type == 'income' ? sum + item.value : sum - item.value);
  }

  List<FlSpot> _generateSpots(List<TransactionModel> txs) {
    final sortedTxs = List<TransactionModel>.from(txs)..sort((a, b) => a.date.compareTo(b.date));
    double balance = 0;
    List<FlSpot> spots = sortedTxs.isEmpty ? [] : [const FlSpot(0, 0)];
    for (int i = 0; i < sortedTxs.length; i++) {
      balance += (sortedTxs[i].type == 'income' ? sortedTxs[i].value : -sortedTxs[i].value);
      spots.add(FlSpot((i + 1).toDouble(), balance));
    }
    return spots;
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

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['BRL', 'BTC', 'USD', 'EUR', 'ETH'].map((coin) => ListTile(
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

  Widget _buildStatementButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.pushNamed('transactions'),
      icon: const Icon(Icons.list_alt),
      label: const Text("Ver Extrato Completo"),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
      ),
    );
  }
}