import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:projeto_estacionamento/core/erros/backend_exception.dart';
import 'package:projeto_estacionamento/features/vagas/models/resumo_vagas.dart';
import 'package:projeto_estacionamento/features/vagas/models/vaga.dart';
import 'package:projeto_estacionamento/features/vagas/repositories/vaga_repository.dart';

/// Backend das VAGAS para o usuário comum: ver quais vagas estão disponíveis.
///
/// Equivale às rotas de consulta do web (/vagas, /vagas/livres, /vagas/total,
/// /vagas/:id) e mais [observarVagas] / [observarResumo], que atualizam a tela
/// sozinhos quando um sensor muda uma vaga no banco.
///
/// Não expõe quem está em cada vaga (placa de outra pessoa é dado pessoal).
class VagaController {
  VagaController({VagaRepository? repository}) : _repository = repository ?? VagaRepository();

  /// Instância única usada pelo app inteiro.
  static final VagaController instancia = VagaController();

  final VagaRepository _repository;

  /// Todas as vagas (para desenhar a grade de bolinhas verde/vermelha).
  Future<List<Vaga>> listarTodas() => _repository.listar();

  /// Só as vagas disponíveis. Use [tipo] para filtrar (ex.: só vagas de idoso).
  Future<List<Vaga>> listarLivres({TipoVaga? tipo}) async {
    final livres = await _repository.listar(ocupada: false);
    return tipo == null ? livres : livres.where((v) => v.tipo == tipo).toList();
  }

  /// Contadores: total, ocupadas, livres e taxa de ocupação.
  Future<ResumoVagas> resumo() => _repository.resumo();

  Future<Vaga> buscarPorId(int id) async {
    final vaga = await _repository.buscarPorId(id);
    if (vaga == null) throw BackendException(CodigoErro.vagaNaoEncontrada);
    return vaga;
  }

  // ------------------------------ Tempo real ------------------------------

  /// Lista de vagas que se atualiza sozinha. Na tela:
  /// `StreamBuilder<List<Vaga>>(stream: VagaController.instancia.observarVagas(), ...)`
  ///
  /// Só emite quando algo mudou. Para de consultar quando a tela fecha.
  Stream<List<Vaga>> observarVagas({Duration intervalo = const Duration(seconds: 5)}) =>
      _observar(listarTodas, intervalo, listEquals);

  /// Contadores que se atualizam sozinhos.
  Stream<ResumoVagas> observarResumo({Duration intervalo = const Duration(seconds: 5)}) =>
      _observar(resumo, intervalo, (a, b) => a == b);

  // ---------------------------------------------------------------------------

  static Stream<T> _observar<T>(
    Future<T> Function() buscar,
    Duration intervalo,
    bool Function(T a, T b) iguais,
  ) {
    late final StreamController<T> controller;
    Timer? timer;
    T? ultimo;
    var temUltimo = false;
    var buscando = false;

    Future<void> atualizar() async {
      if (buscando || controller.isClosed) return;
      buscando = true;
      try {
        final valor = await buscar();
        if (controller.isClosed) return;
        if (!temUltimo || !iguais(valor, ultimo as T)) {
          ultimo = valor;
          temUltimo = true;
          controller.add(valor);
        }
      } catch (erro, pilha) {
        if (controller.isClosed) return;
        temUltimo = false; // quando voltar, emite de novo para a tela sair do erro
        controller.addError(erro, pilha);
      } finally {
        buscando = false;
      }
    }

    void iniciar() {
      timer?.cancel();
      unawaited(atualizar());
      timer = Timer.periodic(intervalo, (_) => atualizar());
    }

    void parar() {
      timer?.cancel();
      timer = null;
    }

    controller = StreamController<T>(
      onListen: iniciar,
      onPause: parar,
      onResume: iniciar,
      onCancel: parar,
    );
    return controller.stream;
  }
}
