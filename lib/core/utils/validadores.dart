import 'dart:convert';

/// Validações usadas pelo backend e prontas para o `validator:` dos
/// TextFormField da tela. Assim a tela e o backend seguem a MESMA regra.
///
/// Exemplo na tela:
///   TextFormField(validator: Validadores.login, ...)
abstract final class Validadores {
  static final _regexEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  // Limites das colunas da tbl_usuario.
  static const tamanhoMaximoNome = 120; // nome_usuario VARCHAR(120)
  static const tamanhoMaximoEmail = 120; // email VARCHAR(120)

  /// Mínimo de caracteres da senha no cadastro (igual ao POST /usuarios do web).
  static const tamanhoMinimoSenha = 6;

  /// O bcrypt só usa os primeiros 72 bytes da senha; acima disso o resto
  /// seria ignorado sem ninguém perceber, então recusamos.
  static const tamanhoMaximoSenhaBytes = 72;

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
    if (texto.length > tamanhoMaximoEmail) {
      return 'O e-mail pode ter no máximo $tamanhoMaximoEmail caracteres';
    }
    return null;
  }

  /// No login só exigimos que a senha tenha sido digitada: a regra de
  /// "senha forte" vale para cadastro/troca, não para entrar.
  static String? senhaLogin(String? valor) {
    if (valor == null || valor.isEmpty) return 'Informe a senha';
    return null;
  }

  // ---------- Cadastro ----------

  static String? nome(String? valor) {
    final texto = normalizarNome(valor ?? '');
    if (texto.isEmpty) return 'Informe o nome';
    if (texto.length < 2) return 'Informe seu nome completo';
    if (texto.length > tamanhoMaximoNome) {
      return 'O nome pode ter no máximo $tamanhoMaximoNome caracteres';
    }
    return null;
  }

  /// Telefone com DDD: 10 dígitos (fixo) ou 11 (celular), com ou sem máscara.
  static String? telefone(String? valor) {
    final digitos = somenteDigitos(valor ?? '');
    if (digitos.isEmpty) return 'Informe o telefone';
    if (digitos.length < 10 || digitos.length > 11) {
      return 'Informe um telefone válido com DDD';
    }
    return null;
  }

  static String? senhaCadastro(String? valor) {
    if (valor == null || valor.isEmpty) return 'Informe a senha';
    if (valor.length < tamanhoMinimoSenha) {
      return 'A senha deve ter pelo menos $tamanhoMinimoSenha caracteres';
    }
    if (utf8.encode(valor).length > tamanhoMaximoSenhaBytes) {
      return 'A senha pode ter no máximo $tamanhoMaximoSenhaBytes caracteres';
    }
    return null;
  }

  // ---------- Normalizações (usadas pelo backend antes de ir ao banco) ----------

  static String somenteDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

  /// E-mail vira minúsculo; telefone vira só dígitos (tira máscara).
  static String normalizarLogin(String texto) {
    final limpo = texto.trim();
    return limpo.contains('@') ? normalizarEmail(limpo) : somenteDigitos(limpo);
  }

  static String normalizarEmail(String texto) => texto.trim().toLowerCase();

  /// Tira espaços das pontas e espaços repetidos no meio ("Maria   Silva").
  static String normalizarNome(String texto) => texto.trim().replaceAll(RegExp(r'\s+'), ' ');
}
