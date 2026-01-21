import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:salve_financas/features/concierge/services/local_concierge_service.dart';

class ConciergeScreen extends StatefulWidget {
  const ConciergeScreen({super.key});

  @override
  State<ConciergeScreen> createState() => _ConciergeScreenState();
}

class _ConciergeScreenState extends State<ConciergeScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  
  // Usa o serviço local (Llama + Isar)
  final LocalConciergeService _service = LocalConciergeService();
  
  // Lista de mensagens: {role: 'user'/'bot', text: '...'}
  final List<Map<String, String>> _messages = [];
  
  bool _isTyping = false; // Bloqueia envio enquanto gera

  @override
  void initState() {
    super.initState();
    // Mensagem inicial de "boot" do sistema
    _addMsg("bot", "Conectado ao Núcleo Local (Arcis AI).\nAnalisando base de dados criptografada...\n\nComo posso auxiliar suas finanças hoje?");
  }

  void _addMsg(String role, String text) {
    setState(() {
      _messages.add({'role': role, 'text': text});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    if (_ctrl.text.isEmpty || _isTyping) return;
    
    final text = _ctrl.text;
    _ctrl.clear();
    
    // 1. Adiciona pergunta do usuário
    _addMsg("user", text);
    
    setState(() => _isTyping = true);

    // 2. Prepara o balão do bot vazio para receber o stream
    _messages.add({'role': 'bot', 'text': ''});
    int botIndex = _messages.length - 1;

    try {
      // 3. Chama o Serviço Local
      final stream = await _service.chat(text);
      
      // 4. Escuta os tokens chegando (Efeito digitação)
      stream.listen(
        (chunk) {
          setState(() {
            _messages[botIndex]['text'] = (_messages[botIndex]['text'] ?? "") + chunk;
          });
          _scrollToBottom();
        },
        onDone: () {
          setState(() => _isTyping = false);
        },
        onError: (e) {
          setState(() {
            _messages[botIndex]['text'] = "Erro de processamento: $e";
            _isTyping = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _messages[botIndex]['text'] = "Falha crítica no motor local: $e";
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.greenAccent),
          onPressed: () => context.go('/dash'),
        ),
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.greenAccent, size: 20),
            SizedBox(width: 10),
            Text("ARCIS LOCAL", style: TextStyle(fontFamily: 'monospace', fontSize: 14, letterSpacing: 2, color: Colors.white)),
          ],
        ),
        actions: [
          // Botão para configurações da IA (Download/Reset)
          IconButton(
            icon: const Icon(Icons.settings_suggest, color: Colors.white24),
            onPressed: () => context.push('/ai_setup'), // Rota para tela de download
          )
        ],
      ),
      body: Column(
        children: [
          // Área de Chat
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.greenAccent.withOpacity(0.1) : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(12),
                      ),
                      border: Border.all(color: isUser ? Colors.greenAccent.withOpacity(0.3) : Colors.white10),
                    ),
                    child: MarkdownBody(
                      data: msg['text']!,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: isUser ? Colors.white : Colors.greenAccent.withOpacity(0.9), 
                          fontFamily: 'monospace',
                          height: 1.4
                        ),
                        strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading discreto
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("PROCESSANDO...", style: TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'monospace')),
            ),

          // Input
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF111111),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    enabled: !_isTyping,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: "Digite seu comando...",
                      hintStyle: const TextStyle(color: Colors.white24, fontFamily: 'monospace'),
                      filled: true,
                      fillColor: Colors.black,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _isTyping ? Colors.grey : Colors.greenAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black, size: 20),
                    onPressed: _handleSend,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}