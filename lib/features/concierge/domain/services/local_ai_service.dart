class LocalAIService {
  // O prompt que "treina" a IA no início da conversa
  String _buildSystemPrompt(UserFinancialData data, List<GoalModel> goals) {
    final rules = _loadRulesFromJson(); // Carrega o financial_rules.json
    
    return """
    Você é o Concierge do app 'Salve Finanças'. 
    Sua base são as normas do Banco Central: ${rules.bacen}.
    Dados atuais do usuário: 
    - Saldo: ${data.balance}
    - Gastos no mês: ${data.monthlyExpenses}
    - Metas ativas: ${goals.map((g) => g.title).join(', ')}.

    Regra de Ouro: Sempre responda em Português Brasileiro, seja breve e encorajador.
    Se o usuário gastar mais de 30% com lazer, alerte sobre o Score de Crédito.
    """;
  }

  Future<String> getRecommendation(String userQuery) async {
    // Aqui entra a lógica do MediaPipe LLM Inference
    // 1. Carrega o modelo (.bin) da memória local
    // 2. Envia o System Prompt + User Query
    // 3. Retorna a resposta
    return "Baseado na sua meta de 'Comprar Carro', sugiro reduzir o iFood em 20% este mês.";
  }
}