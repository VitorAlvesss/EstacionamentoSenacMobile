/// Validações usadas pelo backend e prontas para o `validator:` dos
/// TextFormField da tela. Assim a tela e o backend seguem a MESMA regra.
///
/// Exemplo na tela:
///   TextFormField(validator: Validadores.login, ...)
abstract final class Validadores {
  static final _regexEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Campo de login: aceita e-mail ou telefone (com ou sem máscara), igual ao web.
  static String? login(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe o e-mail ou telefone';
    if (texto.contains('@')) return email(texto);
    final digitos = somenteDigitos(texto);
    if (digitos.length < 10 || digitos.length > 11) {
      return 'Informe um e-mail ou telefone válido';
    }
    return null;
  }

  static String? email(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe o e-mail';
    if (!_regexEmail.hasMatch(texto)) return 'Informe um e-mail válido';
    return null;
  }

  /// No login só exigimos que a senha tenha sido digitada: a regra de
  /// "senha forte" vale para cadastro/troca, não para entrar.
  static String? senhaLogin(String? valor) {
    if (valor == null || valor.isEmpty) return 'Informe a senha';
    return null;
  }

  // ---------- Normalizações (usadas pelo backend antes de ir ao banco) ----------

  static String somenteDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

  /// E-mail vira minúsculo; telefone vira só dígitos (tira máscara).
  static String normalizarLogin(String texto) {
    final limpo = texto.trim();
    return limpo.contains('@') ? limpo.toLowerCase() : somenteDigitos(limpo);
  }
}
