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

  /// Recupera o usuário logado para garantir que os dados exibidos sejam isolados
  Future<void> _loadUser() async {
    // Busca o usuário atual no banco local
    final currentUser = await isar.userModels.where().findFirst();
    if (mounted) {
      setState(() => _user = currentUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Carregamento inicial do perfil
    if (_user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extrato de Lançamentos'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<TransactionModel>>(
        // REQUISITO: Isolamento por ID e atualização em tempo real (watch)
        stream: isar.transactionModels
            .filter()
            .userIdEqualTo(_user!.id)
            .sortByDateDesc()
            .watch(fireImmediately: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final txs = snapshot.data ?? [];
          
          if (txs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  "Nenhum registro encontrado.\nUse o Scanner ou o botão '+' para adicionar.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }

          // Interação de Dados: Calcula totais baseados no que está na tela
          final income = txs.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.value);
          final expense = txs.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.value);

          return Column(
            children: [
              _buildExtratoHeader(income, expense),
              Expanded(
                child: ListView.builder(
                  itemCount: txs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemBuilder: (context, index) => _buildTransactionItem(context, txs[index]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTransactionForm(context),
        label: const Text("Novo Lançamento"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  /// Componente de Resumo (Interação dinâmica com o extrato)
  Widget _buildExtratoHeader(double income, double expense) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryCol("Receitas", income, Colors.greenAccent),
          Container(width: 1, height: 35, color: Colors.white10),
          _summaryCol("Despesas", expense, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _summaryCol(String title, double value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text("R\$ ${value.toStringAsFixed(2)}", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel t) {
    final isExpense = t.type == 'expense';
    final isScan = t.rawText != null && t.rawText!.isNotEmpty;

    return Dismissible(
      key: Key("tx_item_${t.id}"),
      direction: DismissDirection.endToStart,
      confirmDismiss: (dir) => _confirmDelete(context),
      onDismissed: (_) async {
        await isar.writeTxn(() => isar.transactionModels.delete(t.id));
      },
      background: _deleteBg(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          onTap: () => _showTransactionForm(context, existingTx: t),
          leading: CircleAvatar(
            backgroundColor: isExpense ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            child: Icon(
              isExpense ? Icons.arrow_downward : Icons.arrow_upward, 
              color: isExpense ? Colors.redAccent : Colors.greenAccent,
              size: 18,
            ),
          ),
          title: Row(
            children: [
              Expanded(child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold))),
              if (isScan) const Icon(Icons.qr_code_2, size: 14, color: Colors.blueGrey),
            ],
          ),
          subtitle: Text("${t.category} • ${t.date.day}/${t.date.month}"),
          trailing: Text(
            "${isExpense ? '-' : '+'} R\$ ${t.value.toStringAsFixed(2)}", 
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isExpense ? Colors.redAccent : Colors.greenAccent
            ),
          ),
        ),
      ),
    );
  }

  Widget _deleteBg() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.delete_sweep, color: Colors.white),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remover registro?"),
        content: const Text("Essa ação é permanente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Voltar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Apagar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showTransactionForm(BuildContext context, {TransactionModel? existingTx}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _TransactionForm(userId: _user!.id, tx: existingTx),
    );
  }
}

// --- SUB-WIDGET: FORMULÁRIO DE LANÇAMENTO ---

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
  late String _type;
  String _cat = 'Geral';

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.tx?.title ?? "");
    // Trata o valor para exibição amigável
    _valueCtrl = TextEditingController(text: widget.tx?.value == 0.0 ? "" : widget.tx?.value.toString());
    _type = widget.tx?.type ?? 'expense';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.tx != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, 
        left: 24, right: 24, top: 32
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isEdit ? "Editar Detalhes" : "Novo Lançamento", 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Descrição ou Nome da Loja', prefixIcon: Icon(Icons.edit_note)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueCtrl,
            decoration: const InputDecoration(labelText: 'Valor Total (R\$)', prefixText: 'R\$ '),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _type,
            items: const [
              DropdownMenuItem(value: 'expense', child: Text('Despesa')),
              DropdownMenuItem(value: 'income', child: Text('Receita')),
            ],
            onChanged: (v) => setState(() => _type = v!),
            decoration: const InputDecoration(labelText: 'Tipo'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _handleSave(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(isEdit ? "ATUALIZAR" : "CONFIRMAR", 
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_titleCtrl.text.isEmpty || _valueCtrl.text.isEmpty) return;
    
    final val = double.tryParse(_valueCtrl.text.replaceAll(',', '.'));
    if (val == null) return;

    final updatedTx = TransactionModel()
      ..id = widget.tx?.id ?? Isar.autoIncrement
      ..userId = widget.userId // Vínculo com usuário logado
      ..title = _titleCtrl.text
      ..value = val
      ..date = widget.tx?.date ?? DateTime.now()
      ..category = _cat
      ..type = _type
      ..rawText = widget.tx?.rawText;

    await isar.writeTxn(() => isar.transactionModels.put(updatedTx));
    if (mounted) context.pop();
  }
}