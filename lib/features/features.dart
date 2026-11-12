/// Backend do app Estacionamento Senac (mobile).
///
/// As telas (lib/pages) só precisam deste import:
///   import 'package:projeto_estacionamento/features/features.dart';
///
/// - [UsuarioController.instancia] -> login, sessão, logout
/// - [VagaController.instancia]    -> vagas disponíveis (listar, resumo, tempo real)
/// - [Validadores]                 -> validator: dos TextFormField
/// - [BackendException]            -> todo erro vem assim, com `.mensagem` pronta
///
/// Guia completo: docs/BACKEND.md
library;

// core
export '../core/conexao/banco_mysql.dart' show BancoMySql;
export '../core/config/banco_config.dart';
export '../core/erros/backend_exception.dart';
export '../core/utils/validadores.dart';

// usuarios
export 'usuarios/controllers/usuario_controller.dart';
export 'usuarios/models/usuario.dart';

// vagas
export 'vagas/controllers/vaga_controller.dart';
export 'vagas/models/resumo_vagas.dart';
export 'vagas/models/vaga.dart';
