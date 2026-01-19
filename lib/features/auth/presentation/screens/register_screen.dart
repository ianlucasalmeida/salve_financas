import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart'; // Import para acessar a instância global 'isar'
import 'package:salve_financas/features/auth/data/models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Moeda preferida inicial (padrão solicitado para a Dash)
  String _selectedCurrency = 'BTC';

  /// Lógica real de salvamento no Isar
  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newUser = UserModel()
          ..name = _nameController.text.trim()
          ..email = _emailController.text.trim()
          ..password = _passwordController.text // Em produção, utilize hash/criptografia
          ..preferredCurrency = _selectedCurrency;

        // Persistência real no banco de dados local
        await isar.writeTxn(() async {
          await isar.userModels.put(newUser);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Conta criada com sucesso! Faça login para continuar."),
              backgroundColor: Colors.green,
            ),
          );
          
          // Fluxo: Após cadastro, volta para o Login
          context.goNamed('login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao criar conta: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.goNamed('login'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Crie sua conta", 
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, 
                  color: Colors.white
                )
              ),
              const SizedBox(height: 8),
              Text(
                "Comece a gerenciar seu patrimônio com inteligência e precisão.", 
                style: TextStyle(color: Colors.white.withOpacity(0.6))
              ),
              const SizedBox(height: 32),
              
              // Campo: Nome
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nome Completo', 
                  prefixIcon: Icon(Icons.person_outline)
                ),
                validator: (v) => v!.isEmpty ? "Insira seu nome completo" : null,
              ),
              const SizedBox(height: 16),
              
              // Campo: E-mail
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail', 
                  prefixIcon: Icon(Icons.email_outlined)
                ),
                validator: (v) => !v!.contains("@") ? "Insira um e-mail válido" : null,
              ),
              const SizedBox(height: 16),
              
              // Campo: Senha
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Senha', 
                  prefixIcon: Icon(Icons.lock_outline)
                ),
                validator: (v) => v!.length < 6 ? "A senha deve ter no mínimo 6 caracteres" : null,
              ),
              const SizedBox(height: 16),

              // Seletor de Moeda Preferida (Importante para a Dash)
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Moeda de Destaque na Dashboard',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                items: ['BTC', 'USD', 'EUR', 'BRL', 'ETH'].map((coin) {
                  return DropdownMenuItem(value: coin, child: Text(coin));
                }).toList(),
                onChanged: (value) => setState(() => _selectedCurrency = value!),
              ),
              
              const SizedBox(height: 40),

              // Botão de Ação
              ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "CRIAR MINHA CONTA", 
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.1)
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Link para voltar
              TextButton(
                onPressed: () => context.goNamed('login'),
                child: Text(
                  "Já possui uma conta? Faça Login",
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}