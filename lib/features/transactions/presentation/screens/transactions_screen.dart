import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:go_router/go_router.dart';
import 'package:salve_financas/main.dart'; 
import 'package:salve_financas/features/dashboard/data/models/transaction_model.dart';
import 'package:salve_financas/features/auth/data/models/user_model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final currentUser = await isar.userModels.filter().isSessionActiveEqualTo(true).findFirst();
    if (mounted) setState(() => _user = currentUser);
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('EXTRATO DETALHADO', style: TextStyle(fontFamily: 'monospace', letterSpacing: 2, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.greenAccent),
            onPressed: () => context.push('/scanner'),
          )
        ],
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: isar.transactionModels
            .filter()
            .userIdEqualTo(_user!.id)
            .sortByDateDesc()
            .watch(fireImmediately: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
          }

          final txs = snapshot.data ?? [];
          
          if (txs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  const Text("SEM REGISTROS", style: TextStyle(color: Colors.grey, fontFamily: 'monospace')),
                ],
              ),
            );
          }

          final income = txs.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.value);
          final expense = txs.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.value);

          return Column(
            children: [
              _buildSummaryHeader(income, expense),
              Expanded(
                child: ListView.builder(
                  itemCount: txs.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) => _TransactionExpandableCard(
                    transaction: txs[index],
                    onEdit: () => _showTransactionForm(context, existingTx: txs[index]),
                    onDelete: () => _deleteTransaction(txs[index].id),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        onPressed: () => _showTransactionForm(context),
        label: const Text("NOVO", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryHeader(double income, double expense) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statItem("ENTRADAS", income, Colors.greenAccent),
          Container(width: 1, height: 40, color: Colors.white10),
          _statItem("SAÍDAS", expense, Colors.redAccent),
          Container(width: 1, height: 40, color: Colors.white10),
          _statItem("SALDO", income - expense, (income - expense) >= 0 ? Colors.white : Colors.red),
        ],
      ),
    );
  }

  Widget _statItem(String label, double val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text("R\$ ${val.toStringAsFixed(2)}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, fontFamily: 'monospace')),
      ],
    );
  }

  Future<void> _deleteTransaction(int id) async {
    await isar.writeTxn(() => isar.transactionModels.delete(id));
  }

  void _showTransactionForm(BuildContext context, {TransactionModel? existingTx}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _TransactionForm(userId: _user!.id, tx: existingTx),
    );
  }
}

// ============================================================================
// WIDGET DO CARTÃO EXPANSÍVEL (ATUALIZADO COM DETALHES DE PAGAMENTO)
// ============================================================================
class _TransactionExpandableCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionExpandableCard({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final color = isExpense ? Colors.redAccent : Colors.greenAccent;
    final hasItems = transaction.items != null && transaction.items!.isNotEmpty;
    
    // Recupera dados extras se existirem (assumindo que o model foi atualizado ou usando defaults)
    // Se o seu model ainda não tem paymentMethod, adicione-o. Aqui simulo a leitura.
    final String payment = transaction.paymentMethod ?? 'Débito'; 
    final int installments = transaction.installments ?? 1;

    return Card(
      color: const Color(0xFF0F0F0F),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isExpense ? Icons.shopping_bag_outlined : Icons.attach_money,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            transaction.title.toUpperCase(), // Nome da Loja/Descrição
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              Text(
                "${transaction.date.day}/${transaction.date.month} • ${transaction.category}",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (isExpense && installments > 1) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                  child: Text("${installments}x", style: const TextStyle(fontSize: 10, color: Colors.orangeAccent)),
                )
              ]
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "R\$ ${transaction.value.toStringAsFixed(2)}",
                style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey)
            ],
          ),
          
          // --- DETALHES EXPANDIDOS ---
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF050505),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DETALHES DO PAGAMENTO
                  Row(
                    children: [
                      const Icon(Icons.credit_card, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text("PAGAMENTO: ${payment.toUpperCase()}", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      if (installments > 1)
                        Text(" (${installments}x de R\$ ${(transaction.value / installments).toStringAsFixed(2)})", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // LISTA DE PRODUTOS (NOTA FISCAL)
                  if (hasItems) ...[
                    const Text("ITENS DA NOTA", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    ...transaction.items!.map((item) => _buildReceiptRow(item)),
                    const Divider(color: Colors.white10, height: 24),
                  ] else 
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("• Sem lista de produtos detalhada.", style: TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic)),
                    ),

                  // AÇÕES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text("EXCLUIR", style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                        icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                        label: const Text("EDITAR", style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(TransactionItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 35,
            child: Text(
              "${item.quantity?.toStringAsFixed(0) ?? 1}x",
              style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            child: Text(
              item.name ?? "Produto Desconhecido",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Text(
            "R\$ ${item.totalPrice?.toStringAsFixed(2) ?? '0.00'}",
            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FORMULÁRIO (ATUALIZADO COM PAGAMENTO E PARCELAS)
// ============================================================================
class _TransactionForm extends StatefulWidget {
  final int userId;
  final TransactionModel? tx;
  const _TransactionForm({required this.userId, this.tx});

  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  late TextEditingController _titleCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _installmentsCtrl;
  late String _type;
  late String _cat;
  late String _paymentMethod; // Novo campo

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.tx?.title ?? "");
    _valueCtrl = TextEditingController(text: widget.tx?.value.toStringAsFixed(2) ?? "");
    _installmentsCtrl = TextEditingController(text: (widget.tx?.installments ?? 1).toString());
    _type = widget.tx?.type ?? 'expense';
    _cat = widget.tx?.category ?? 'Geral';
    _paymentMethod = widget.tx?.paymentMethod ?? 'Crédito';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24, 
        left: 24, right: 24, top: 32
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.tx != null ? "EDITAR REGISTRO" : "NOVO LANÇAMENTO", 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent, letterSpacing: 2)),
          const SizedBox(height: 24),
          
          _inputField("Loja / Estabelecimento", _titleCtrl, icon: Icons.store),
          const SizedBox(height: 16),
          _inputField("Valor Total (R\$)", _valueCtrl, icon: Icons.attach_money, isNumber: true),
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _type,
                  dropdownColor: const Color(0xFF222222),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco("Tipo"),
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text('Despesa')),
                    DropdownMenuItem(value: 'income', child: Text('Receita')),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  dropdownColor: const Color(0xFF222222),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco("Pagamento"),
                  items: const [
                    DropdownMenuItem(value: 'Crédito', child: Text('Crédito')),
                    DropdownMenuItem(value: 'Débito', child: Text('Débito')),
                    DropdownMenuItem(value: 'PIX', child: Text('PIX')),
                    DropdownMenuItem(value: 'Dinheiro', child: Text('Dinheiro')),
                  ],
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
              ),
            ],
          ),

          // Campo de Parcelas (Só aparece se for Crédito e Despesa)
          if (_type == 'expense' && _paymentMethod == 'Crédito') ...[
            const SizedBox(height: 16),
            _inputField("Nº Parcelas", _installmentsCtrl, icon: Icons.calendar_view_week, isNumber: true),
          ],
          
          const SizedBox(height: 32),
          
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("SALVAR DADOS", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, {IconData? icon, bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDeco(label, icon: icon),
    );
  }

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: icon != null ? Icon(icon, color: Colors.greenAccent, size: 20) : null,
      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.greenAccent), borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
    );
  }

  Future<void> _save() async {
    final val = double.tryParse(_valueCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final parc = int.tryParse(_installmentsCtrl.text) ?? 1;
    if (_titleCtrl.text.isEmpty || val <= 0) return;

    final updatedTx = TransactionModel()
      ..id = widget.tx?.id ?? Isar.autoIncrement
      ..userId = widget.userId
      ..title = _titleCtrl.text
      ..value = val
      ..date = widget.tx?.date ?? DateTime.now()
      ..category = _cat
      ..type = _type
      ..paymentMethod = _paymentMethod // ✅ Salvando para a IA ler depois
      ..installments = parc // ✅ Salvando para a IA ler depois
      ..rawText = widget.tx?.rawText
      ..items = widget.tx?.items;

    await isar.writeTxn(() => isar.transactionModels.put(updatedTx));
    if (mounted) context.pop();
  }
}