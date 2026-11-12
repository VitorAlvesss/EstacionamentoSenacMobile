import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:projeto_estacionamento/features/usuarios/models/usuario.dart';

/// Onde a sessão fica guardada para o usuário não precisar logar toda vez.
abstract interface class ArmazenamentoSessao {
  Future<Usuario?> ler();
  Future<void> salvar(Usuario usuario);
  Future<void> limpar();
}

/// Guarda no próprio celular (SharedPreferences). Só dados públicos do usuário,
/// nunca a senha.
class ArmazenamentoSessaoLocal implements ArmazenamentoSessao {
  static const _chave = 'estacionamento.sessao.usuario';

  @override
  Future<Usuario?> ler() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chave);
    if (texto == null) return null;
    try {
      return Usuario.deJson(Map<String, Object?>.from(jsonDecode(texto) as Map));
    } catch (_) {
      await prefs.remove(_chave); // dado corrompido: descarta
      return null;
    }
  }

  @override
  Future<void> salvar(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, jsonEncode(usuario.paraJson()));
  }

  @override
  Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }
}

/// Só em memória (some ao fechar o app). Usado nos testes.
class ArmazenamentoSessaoMemoria implements ArmazenamentoSessao {
  Usuario? _usuario;

  @override
  Future<Usuario?> ler() async => _usuario;

  @override
  Future<void> salvar(Usuario usuario) async => _usuario = usuario;

  @override
  Future<void> limpar() async => _usuario = null;
}
