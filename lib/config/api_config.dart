class ApiConfig {
  // Lê a chave passada via --dart-define ou usa a chave fallback para testes locais
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // <-- Se quiser testar localmente, substitua aqui
  );
}