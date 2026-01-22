# 💸 Salve Finanças

![Logo](assets/images/salve_logo4.png)

> **Concierge Financeiro Local & Inteligente.**
> Controle suas finanças com privacidade total, inteligência artificial rodando no dispositivo e uma interface premium.

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)](https://flutter.dev)
[![Isar](https://img.shields.io/badge/Database-Isar-brightgreen)](https://isar.dev)
[![AI](https://img.shields.io/badge/AI-Local%20Llama-orange)](https://github.com/ggerganov/llama.cpp)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## 📖 Sobre o Projeto

O **Salve Finanças** não é apenas mais um gerenciador de gastos. É uma plataforma de engenharia financeira pessoal focada em **Privacidade (Offline-First)** e **Performance**.

Diferente de apps que enviam seus dados bancários para a nuvem, o Salve Finanças processa tudo localmente no seu dispositivo. Ele utiliza um modelo de linguagem (LLM) embarcado para atuar como um "Concierge", analisando seus gastos, sugerindo economias e respondendo perguntas sobre sua saúde financeira sem que um único byte de dados saia do seu celular.

## ✨ Funcionalidades Principais

* **📊 Dashboard Interativo:**
    * Evolução financeira com gráficos de linha suavizados (`fl_chart`).
    * Análise de despesas por categoria.
    * Monitoramento de metas e objetivos em tempo real.
* **🤖 Concierge AI (Offline):**
    * Chat inteligente integrado com o modelo **Llama** rodando nativamente no Android.
    * Análise de contexto financeiro sem internet.
* **💰 Gestão de Carteira (Metas):**
    * Criação de "Caixinhas" para objetivos específicos.
    * Visualização de progresso individual por meta (Gráfico colorido).
    * Simulador de aportes e rendimentos.
* **📝 Transações Detalhadas:**
    * Registro de Receitas e Despesas.
    * Suporte a métodos de pagamento (Crédito, Débito, PIX, Dinheiro).
    * Controle de parcelamento de compras.
* **📷 Scanner Inteligente (OCR):**
    * Digitalização de notas fiscais via câmera.
    * Extração automática de itens e valores usando ML Kit.
* **🎨 UI/UX Premium:**
    * Modo Escuro (Dark Mode) nativo e elegante.
    * Animações fluidas e transições de tela.
    * Splash Screen animada com vetores SVG.

## 🛠 Tech Stack

O projeto utiliza as tecnologias mais modernas do ecossistema Flutter:

| Categoria | Tecnologia / Pacote | Descrição |
| :--- | :--- | :--- |
| **Framework** | Flutter | UI Toolkit do Google. |
| **Linguagem** | Dart | Linguagem tipada e otimizada. |
| **Banco de Dados** | **Isar** | NoSQL super rápido, ACID e totalmente local. |
| **Gerência de Estado** | `setState` / Services | Arquitetura limpa e reativa. |
| **Rotas** | GoRouter | Navegação declarativa e profunda. |
| **Gráficos** | Fl_Chart | Renderização de gráficos complexos e interativos. |
| **IA Local** | `llama_flutter_android` | Inferência de LLMs no dispositivo (Edge AI). |
| **OCR / ML** | Mobile Scanner / ML Kit | Leitura de códigos e reconhecimento de texto. |
| **Utilitários** | `flutter_svg`, `intl` | Renderização vetorial e formatação. |

## 🚀 Como Rodar o Projeto

### Pré-requisitos
* Flutter SDK instalado (Versão 3.x+).
* Android Studio / VS Code configurados.
* Dispositivo Android (Físico ou Emulador) configurado (Min SDK 21).

### Instalação

1.  **Clone o repositório:**
    ```bash
    git clone [https://github.com/ianlucasalmeida/salve_financas.git](https://github.com/ianlucasalmeida/salve_financas.git)
    cd salve_financas
    ```

2.  **Instale as dependências:**
    ```bash
    flutter pub get
    ```

3.  **Gere os arquivos de código (Isar & Models):**
    *Este passo é crucial para o funcionamento do banco de dados.*
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  **Execute o projeto:**
    ```bash
    flutter run
    ```

## 📂 Estrutura do Projeto

O projeto segue uma arquitetura baseada em **Features**, garantindo escalabilidade e manutenção:

lib/ ├── assets/ # Imagens, SVGs e Regras de Contexto da IA ├── core/ # Widgets compartilhados, temas, utils ├── features/ │ ├── auth/ # Login, Cadastro e Perfil │ ├── dashboard/ # Tela principal, Gráficos │ ├── wallet/ # Metas, Caixinhas e Simulador │ ├── transactions/ # Extrato, Formulários e Scanner │ ├── concierge/ # Chat e Lógica da IA Local │ └── splash/ # Tela de abertura animada ├── main.dart # Ponto de entrada e Configuração de Rotas └── ...


## 🧪 IA e Modelos

O projeto utiliza um arquivo `context_rules.json` localizado em `assets/` para definir a "persona" do Concierge Financeiro. O modelo Llama deve ser baixado ou configurado conforme as instruções na pasta `features/concierge`.

## 🤝 Contribuição

Contribuições são bem-vindas! Se você tiver uma ideia para melhorar o Salve Finanças:

1.  Faça um Fork do projeto.
2.  Crie uma Branch para sua Feature (`git checkout -b feature/IncrivelFeature`).
3.  Faça o Commit (`git commit -m 'Add some IncrivelFeature'`).
4.  Faça o Push (`git push origin feature/IncrivelFeature`).
5.  Abra um Pull Request.

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---
<div align="center">
  <sub>Desenvolvido com 💚 e muito café.</sub>
</div>