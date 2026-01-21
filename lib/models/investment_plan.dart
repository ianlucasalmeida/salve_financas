class InvestmentPlan {
  final double initialAmount;
  final double monthlyContribution;
  final double annualRate;
  final int periodMonths;

  InvestmentPlan({
    required this.initialAmount,
    required this.monthlyContribution,
    required this.annualRate,
    required this.periodMonths,
  });

  /// Lógica 1: Juros Compostos (A que você pediu)
  double calculateCompoundInterest() {
    double current = initialAmount;
    // Taxa mensal = (Taxa Anual / 100) / 12
    double monthlyRate = (annualRate / 100) / 12;

    for (int i = 0; i < periodMonths; i++) {
      // O aporte rende juros no mês seguinte ou no mesmo, dependendo da regra. 
      // Aqui aplicamos a regra padrão: (Saldo Anterior + Aporte) * Rendimento
      current = (current + monthlyContribution) * (1 + monthlyRate);
    }
    return current;
  }

  /// Lógica 2: Juros Simples (Apenas para comparação/opção)
  double calculateSimpleInterest() {
    // Fórmula: J = P * i * n
    double monthlyRate = (annualRate / 100) / 12;
    double interestOnPrincipal = initialAmount * monthlyRate * periodMonths;
    double interestOnContributions = monthlyContribution * periodMonths * monthlyRate * (periodMonths + 1) / 2; // Progressão aritmética aproximada
    
    return initialAmount + (monthlyContribution * periodMonths) + interestOnPrincipal + interestOnContributions;
  }
}