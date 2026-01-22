import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:salve_financas/features/concierge/services/local_concierge_service.dart';
import 'package:salve_financas/features/concierge/services/file_extraction_service.dart';
import 'package:salve_financas/features/concierge/services/invoice_parser_service.dart';
import 'package:salve_financas/features/concierge/services/chat_history_service.dart'; // ✅ Import do Histórico

class ConciergeScreen extends StatefulWidget {
  const ConciergeScreen({super.key});

  @override
  State<ConciergeScreen> createState() => _ConciergeScreenState();
}

class _ConciergeScreenState extends State<ConciergeScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  
  // Serviços
  final LocalConciergeService _service = LocalConciergeService();
  final FileExtractionService _fileService = FileExtractionService();
  final InvoiceParserService _parser = InvoiceParserService();
  final ChatHistoryService _historyService = ChatHistoryService(); // ✅ Instância do Histórico
  
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  
  // Variáveis de anexo
  String? _pendingAttachmentText;
  String? _pendingAttachmentName;

  @override
  void initState() {
    super.initState();
    _loadHistory(); // ✅ Carrega conversas antigas ao abrir
  }

  // --- LÓGICA DE HISTÓRICO ---
  Future<void> _loadHistory() async {
    final history = await _historyService.getHistory();
    
    if (history.isEmpty) {
      // Mensagem inicial (sem salvar no banco ainda)
      _addMsg("bot", "Olá! Sou o Concierge do Salve Finanças.\nPosso analisar seus gastos ou ler faturas (PDF/Imagem).", saveToDb: false);
    } else {
      setState(() {
        for (var msg in history) {
          _messages.add({'role': msg.role, 'text': msg.text});
        }
      });
      // Rola para o fim após carregar
      Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
    }
  }

  Future<void> _clearChat() async {
    await _historyService.clearHistory();
    setState(() {
      _messages.clear();
    });
    _addMsg("bot", "Histórico limpo. Como posso ajudar agora?", saveToDb: true);
  }
  // ---------------------------

  void _addMsg(String role, String text, {bool saveToDb = true}) {
    setState(() {
      _messages.add({'role': role, 'text': text});
    });
    _scrollToBottom();

    if (saveToDb) {
      _historyService.saveMessage(role, text); // ✅ Salva no banco
    }
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

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            title: const Text("Fatura em PDF", style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              _processFile(isPdf: true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image, color: Colors.blueAccent),
            title: const Text("Foto da Fatura (Galeria)", style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              _processFile(isPdf: false, fromCamera: false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.greenAccent),
            title: const Text("Tirar Foto Agora", style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              _processFile(isPdf: false, fromCamera: true);
            },
          ),
        ],
      ),
    );
  }

  // --- LÓGICA DE PROCESSAMENTO E LIMPEZA DE DADOS ---
  Future<void> _processFile({required bool isPdf, bool fromCamera = false}) async {
    setState(() => _isTyping = true);
    try {
      FileExtractionResult? result;
      
      if (isPdf) {
        result = await _fileService.pickAndReadPdf();
      } else {
        result = await _fileService.pickAndReadImage(fromCamera: fromCamera);
      }

      if (result != null) {
        // O Parser limpa ruídos e corrige valores
        final transactions = _parser.parseRawText(result.text);
        
        StringBuffer cleanTextBuffer = StringBuffer();
        
        if (transactions.isNotEmpty) {
          cleanTextBuffer.writeln("EXTRATO IDENTIFICADO (PROCESSADO):");
          for (var t in transactions) {
            final dateStr = "${t.date.day.toString().padLeft(2,'0')}/${t.date.month.toString().padLeft(2,'0')}";
            cleanTextBuffer.writeln("- $dateStr | ${t.description} | R\$ ${t.value.toStringAsFixed(2)}");
          }
        } else {
          cleanTextBuffer.write(result.text);
        }

        final finalText = cleanTextBuffer.toString();

        setState(() {
          _pendingAttachmentText = finalText;
          _pendingAttachmentName = isPdf ? "Fatura (Processada)" : "Imagem (Processada)";
          
          if (transactions.isNotEmpty) {
            _ctrl.text = "Analise estes ${transactions.length} itens e categorize meus gastos.";
          } else {
            _ctrl.text = "Analise este documento.";
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Sucesso! ${transactions.length} transações identificadas."),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao ler arquivo: $e")));
    } finally {
      setState(() => _isTyping = false);
    }
  }

  Future<void> _handleSend() async {
    if (_ctrl.text.isEmpty || _isTyping) return;
    
    final text = _ctrl.text;
    final attachment = _pendingAttachmentText;
    
    _ctrl.clear();
    setState(() {
      _pendingAttachmentText = null;
      _pendingAttachmentName = null;
    });
    
    String displayMsg = text;
    if (attachment != null) {
      displayMsg = "📎 [Arquivo Anexado]\n$text";
    }

    // 1. Salva mensagem do Usuário no banco
    _addMsg("user", displayMsg, saveToDb: true); 
    setState(() => _isTyping = true);

    _messages.add({'role': 'bot', 'text': ''});
    int botIndex = _messages.length - 1;
    String fullBotResponse = ""; // Acumulador para salvar no final

    try {
      final stream = await _service.chat(text, attachmentText: attachment);
      
      stream.listen(
        (chunk) {
          fullBotResponse += chunk;
          setState(() {
            _messages[botIndex]['text'] = fullBotResponse;
          });
          _scrollToBottom();
        },
        onDone: () {
          setState(() => _isTyping = false);
          // 2. Salva resposta completa do Bot no banco
          if (fullBotResponse.isNotEmpty) {
            _historyService.saveMessage('bot', fullBotResponse); 
          }
        },
        onError: (e) => setState(() {
          _messages[botIndex]['text'] = "Erro: $e";
          _isTyping = false;
        }),
      );
    } catch (e) {
      setState(() {
        _messages[botIndex]['text'] = "Erro crítico: $e";
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.greenAccent),
          onPressed: () => context.go('/dash'),
        ),
        title: const Text("CONCIERGE", style: TextStyle(fontFamily: 'monospace', fontSize: 16, color: Colors.white)),
        actions: [
          // ✅ Botão de Limpar Histórico
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white54),
            tooltip: "Limpar conversa",
            onPressed: _clearChat,
          )
        ],
      ),
      body: Column(
        children: [
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
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isUser ? Colors.greenAccent.withOpacity(0.3) : Colors.white10),
                    ),
                    child: MarkdownBody(
                      data: msg['text']!,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.white, height: 1.4),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(color: Colors.greenAccent, backgroundColor: Colors.transparent, minHeight: 2),
            ),

          if (_pendingAttachmentName != null)
            Container(
              color: const Color(0xFF222222),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Anexo: $_pendingAttachmentName", 
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 16),
                    onPressed: () => setState(() {
                      _pendingAttachmentName = null;
                      _pendingAttachmentText = null;
                    }),
                  )
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF111111),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.white54),
                  onPressed: _showAttachmentOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    enabled: !_isTyping,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Digite...",
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.black,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.greenAccent),
                  onPressed: _handleSend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}