import 'package:flutter/material.dart';

import 'package:projeto_estacionamento/features/features.dart';
import 'package:projeto_estacionamento/pages/componentes/visual_formulario.dart';
import 'package:projeto_estacionamento/pages/login_page.dart';

/// Tela que abre depois do login. Provisória: mostra quem está logado e o
/// resumo das vagas em tempo real. Troque pela Home do time quando ela existir
/// (basta mudar o destino em login_page.dart e main.dart).
class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  // Criado UMA vez: atualiza sozinho a cada 5 s e para quando a tela fecha.
  late final Stream<ResumoVagas> _resumo = VagaController.instancia.observarResumo();

  Future<void> _sair() async {
    await UsuarioController.instancia.sair();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = UsuarioController.instancia.usuarioAtual;

    return Scaffold(
      backgroundColor: CoresApp.fundo,
      appBar: AppBar(
        backgroundColor: CoresApp.laranja,
        foregroundColor: Colors.white,
        title: Text(usuario == null ? 'Estacionamento Senac' : 'Olá, ${usuario.primeiroNome}!'),
        actions: [
          IconButton(onPressed: _sair, tooltip: 'Sair', icon: const Icon(Icons.logout)),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: StreamBuilder<ResumoVagas>(
            stream: _resumo,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                final erro = snapshot.error;
                return Text(
                  erro is BackendException ? erro.mensagem : 'Não foi possível carregar as vagas',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                );
              }
              final resumo = snapshot.data;
              if (resumo == null) return const CircularProgressIndicator(color: CoresApp.laranja);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_parking,
                    size: 72,
                    color: resumo.lotado ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    resumo.lotado ? 'Estacionamento lotado' : '${resumo.livres} vagas livres',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${resumo.ocupacaoTexto} ocupadas (${resumo.taxaOcupacaoTexto})',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
