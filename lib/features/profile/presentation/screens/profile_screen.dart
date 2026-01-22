import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:salve_financas/main.dart';
import 'package:salve_financas/features/auth/data/models/user_model.dart';
import 'package:salve_financas/features/dashboard/data/models/transaction_model.dart';
import 'package:isar/isar.dart';
import 'dart:math';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  /// Recupera o usuário da sessão atual para isolamento de dados
  Future<void> _loadCurrentUserData() async {
    final user = await isar.userModels.where().findFirst();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Perfil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Sair da Conta',
            onPressed: () => context.go('/login'),
          )
        ],
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: isar.transactionModels
            .filter()
            .userIdEqualTo(_currentUser!.id)
            .watch(fireImmediately: true),
        builder: (context, snapshot) {
          final txs = snapshot.data ?? [];
          
          final balance = txs.fold(0.0, (sum, t) => 
            t.type == 'income' ? sum + t.value : sum - t.value);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // 1. Cabeçalho com Foto
              _buildUserHeader(context),

              const SizedBox(height: 32),

              // 2. Econômetro Dinâmico
              _buildEconometroSection(balance),

              const SizedBox(height: 32),

              // 3. Área de Configurações
              const Text(
                "Preferências do App",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              _buildSettingsCard(context),
              
              const SizedBox(height: 40),
              
              // 4. Manutenção de Dados
              _buildDataMaintenanceSection(context),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGETS DE CONSTRUÇÃO ---

  Widget _buildUserHeader(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: _currentUser?.profilePicPath != null 
                ? AssetImage(_currentUser!.profilePicPath!) 
                : null,
              child: _currentUser?.profilePicPath == null
                ? Icon(Icons.person, size: 60, color: Theme.of(context).primaryColor)
                : null,
            ),
            Positioned(
              bottom: 0,
              right: 4,
              child: GestureDetector(
                onTap: () => _pickProfileImage(),
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  radius: 18,
                  child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _currentUser?.name ?? "Usuário",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          _currentUser?.email ?? "",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEconometroSection(double balance) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "ECONÔMETRO",
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 12),
            ),
            const SizedBox(height: 24),
            CustomPaint(
              size: const Size(200, 100),
              painter: FiatEconometerPainter(balance: balance),
            ),
            const SizedBox(height: 20),
            Text(
              balance >= 0 ? "BOM SER FINANCEIRO" : "CONSUMO ELEVADO",
              style: TextStyle(
                color: balance >= 0 ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.currency_exchange, size: 20),
            title: const Text("Moeda de Destaque"),
            trailing: Text(
              _currentUser?.preferredCurrency ?? "BRL",
              style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
            ),
            onTap: () => _showCurrencyPicker(context),
          ),
          const Divider(height: 1, indent: 55),
          
          ListTile(
            leading: const Icon(Icons.memory, size: 20, color: Colors.greenAccent),
            title: const Text("Sistema Neural & IA"),
            subtitle: const Text("Gerenciar modelo local"),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.push('/settings'),
          ),
          const Divider(height: 1, indent: 55),

          // --- 🟢 NOVO BOTÃO: CALCULADORAS DE JUROS ---
          ListTile(
            leading: const Icon(Icons.calculate, size: 20, color: Colors.orangeAccent),
            title: const Text("Calculadoras Financeiras"),
            subtitle: const Text("Juros Simples, Compostos & ROI"),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => _showCalculatorsModal(context), // Abre o menu de opções
          ),
          const Divider(height: 1, indent: 55),
          // -------------------------------------------

          ListTile(
            leading: const Icon(Icons.shield_outlined, size: 20),
            title: const Text("Privacidade e Segurança"),
            subtitle: const Text("Dados isolados por perfil"),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDataMaintenanceSection(BuildContext context) {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () => _confirmDataWipe(context),
          icon: const Icon(Icons.delete_sweep_outlined, color: Colors.grey, size: 20),
          label: const Text(
            "Limpar histórico de transações", 
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // --- LÓGICA DE INTERAÇÃO ---

  // 🟢 MENU DE CALCULADORAS (NOVO)
  void _showCalculatorsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Wrap(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.calculate, color: Colors.orangeAccent),
                const SizedBox(width: 10),
                const Text("Ferramentas de Cálculo", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.trending_up, color: Colors.greenAccent),
            title: const Text("Juros Compostos", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Projeção de investimentos a longo prazo", style: TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navegar para tela de Juros Compostos
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calculadora de Juros Compostos em breve")));
            },
          ),
          ListTile(
            leading: const Icon(Icons.percent, color: Colors.blueAccent),
            title: const Text("Juros Simples", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Cálculo de rendimentos básicos", style: TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navegar para tela de Juros Simples
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calculadora de Juros Simples em breve")));
            },
          ),
          ListTile(
            leading: const Icon(Icons.house, color: Colors.redAccent),
            title: const Text("Financiamento (Price/SAC)", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Simulador de parcelas de imóveis/veículos", style: TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navegar para tela de Financiamento
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Simulador de Financiamento em breve")));
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['BTC', 'USD', 'EUR', 'BRL', 'ETH'].map((coin) => ListTile(
            title: Text(coin, style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () async {
              await isar.writeTxn(() async {
                _currentUser!.preferredCurrency = coin;
                await isar.userModels.put(_currentUser!);
              });
              setState(() {});
              if (mounted) context.pop();
            },
          )).toList(),
        ),
      ),
    );
  }

  void _pickProfileImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Acesse a Galeria para atualizar a foto (em breve)")),
    );
  }

  void _confirmDataWipe(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Limpar Dados?"),
        content: const Text("Isso apagará permanentemente apenas o histórico deste usuário."),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              await isar.writeTxn(() => 
                isar.transactionModels.filter().userIdEqualTo(_currentUser!.id).deleteAll()
              );
              if (mounted) context.pop();
            },
            child: const Text("Confirmar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// --- PAINTER DO ECONÔMETRO (ESTILO FIAT) ---

class FiatEconometerPainter extends CustomPainter {
  final double balance;
  FiatEconometerPainter({required this.balance});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);

    canvas.drawArc(rect, 3.14, 1.04, false, paint..color = Colors.red.withOpacity(0.7));
    canvas.drawArc(rect, 4.18, 1.04, false, paint..color = Colors.orange.withOpacity(0.7));
    canvas.drawArc(rect, 5.22, 1.04, false, paint..color = Colors.greenAccent.withOpacity(0.7));

    final pointerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    double angle;
    if (balance <= -1000) {
      angle = 3.4;
    } else if (balance >= 2000) {
      angle = 6.0;
    } else {
      angle = 4.7 + (balance / 2000);
    }

    canvas.drawLine(
      Offset(size.width / 2, size.height),
      Offset(size.width / 2 + 75 * cos(angle), size.height + 75 * sin(angle)),
      pointerPaint,
    );
    
    canvas.drawCircle(Offset(size.width / 2, size.height), 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}