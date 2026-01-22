import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart';
import 'package:salve_financas/features/auth/data/models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _selectedCurrency = 'BRL';

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final newUser = UserModel()
        ..name = _nameCtrl.text.trim()
        ..email = _emailCtrl.text.trim()
        ..password = _passCtrl.text // ✅ Salvando no campo 'password'
        ..preferredCurrency = _selectedCurrency
        ..isSessionActive = false;

      await isar.writeTxn(() async => await isar.userModels.put(newUser));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Conta criada! Acesse agora."), backgroundColor: Colors.green)
        );
        context.go('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Nova Conta", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text("Defina sua base de inteligência financeira.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Nome Completo", prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v!.isEmpty ? "Obrigatório" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "E-mail", prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => !v!.contains("@") ? "E-mail inválido" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Senha", prefixIcon: Icon(Icons.lock_outline)),
                validator: (v) => v!.length < 6 ? "Mínimo 6 dígitos" : null,
              ),
              const SizedBox(height: 24),
              // --- REGRA DE NEGÓCIO: MOEDA ---
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Moeda de Preferência", prefixIcon: Icon(Icons.currency_exchange)),
                items: ['BRL', 'USD', 'BTC', 'EUR'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCurrency = v!),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: Colors.greenAccent),
                child: const Text("CRIAR CONTA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}