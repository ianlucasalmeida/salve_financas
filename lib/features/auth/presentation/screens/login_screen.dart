import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart';
import 'package:salve_financas/features/auth/data/models/user_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    try {
      final user = await isar.userModels.filter().emailEqualTo(email, caseSensitive: false).findFirst();

      if (user != null && user.password == password) { // ✅ Comparando com 'password'
        await isar.writeTxn(() async {
          user.isSessionActive = true;
          await isar.userModels.put(user);
        });
        if (mounted) context.go('/dash');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("E-mail ou senha incorretos"), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.account_balance_wallet, size: 80, color: Colors.greenAccent),
              const SizedBox(height: 32),
              const Text("Bem-vindo de volta", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 48),
              TextField(
                controller: _emailCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "E-mail", prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Senha", prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text("ENTRAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white10)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("OU", style: TextStyle(color: Colors.white24))),
                  Expanded(child: Divider(color: Colors.white10)),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white, size: 20),
                label: const Text("Entrar com Google", style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.white10)),
              ),
              const SizedBox(height: 24),
              TextButton(onPressed: () => context.push('/register'), child: const Text("Ainda não tem conta? Crie agora", style: TextStyle(color: Colors.greenAccent))),
            ],
          ),
        ),
      ),
    );
  }
}