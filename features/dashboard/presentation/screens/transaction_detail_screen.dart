// features/dashboard/presentation/screens/transaction_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart';
import 'package:salve_financas/features/dashboard/data/models/transaction_model.dart';

class TransactionDetailScreen extends StatelessWidget {
  final int transactionId;
  
  const TransactionDetailScreen({super.key, required this.transactionId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Nota Fiscal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareTransaction(context),
          ),
        ],
      ),
      body: FutureBuilder<TransactionModel?>(
        future: isar.transactionModels.get(transactionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Nota fiscal não encontrada'));
          }
          
          final transaction = snapshot.data!;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Cabeçalho
              _buildHeader(transaction),
              
              const SizedBox(height: 24),
              
              // Detalhes da empresa
              _buildCompanyInfo(transaction),
              
              const SizedBox(height: 24),
              
              // Itens da nota
              _buildItemsList(transaction),
              
              const SizedBox(height: 24),
              
              // Resumo financeiro
              _buildFinancialSummary(transaction),
              
              const SizedBox(height: 32),
              
              // Botões de ação
              _buildActionButtons(context, transaction),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildHeader(TransactionModel transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${transaction.date.day}/${transaction.date.month}/${transaction.date.year} ${transaction.date.hour}:${transaction.date.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (transaction.accessKey != null)
              Text(
                'Chave: ${transaction.accessKey}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompanyInfo(TransactionModel transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações da Empresa',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if (transaction.cnpj != null)
              _buildInfoRow('CNPJ', _formatCNPJ(transaction.cnpj!)),
            if (transaction.status != null)
              _buildInfoRow('Status', transaction.status!),
            _buildInfoRow('Categoria', transaction.category),
          ],
        ),
      ),
    );
  }
  
  Widget _buildItemsList(TransactionModel transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Itens Comprados',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if (transaction.items.isEmpty)
              const Center(
                child: Text(
                  'Nenhum item registrado',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...transaction.items.map((item) => _buildItemRow(item)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildItemRow(NfceItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (item.code.isNotEmpty)
                  Text(
                    'Código: ${item.code}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.quantity} x R\$${item.unitValue.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'R\$${item.totalValue.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFinancialSummary(TransactionModel transaction) {
    final totalItens = transaction.items.fold(
      0.0, (sum, item) => sum + item.totalValue);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo Financeiro',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Total Itens', totalItens),
            _buildSummaryRow('Total Nota', transaction.value),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'R\$${transaction.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            'R\$${value.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context, TransactionModel transaction) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Voltar'),
            onPressed: () => context.pop(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Exportar'),
            onPressed: () => _exportTransaction(transaction),
          ),
        ),
      ],
    );
  }
  
  String _formatCNPJ(String cnpj) {
    if (cnpj.length == 14) {
      return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12)}';
    }
    return cnpj;
  }
  
  void _shareTransaction(BuildContext context) {
    // Implementar compartilhamento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compartilhamento em desenvolvimento')),
    );
  }
  
  void _exportTransaction(TransactionModel transaction) {
    // Implementar exportação para PDF/Excel
  }
}