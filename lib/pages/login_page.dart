import 'package:flutter/material.dart';

import 'package:projeto_estacionamento/features/features.dart';
import 'package:projeto_estacionamento/pages/cadastro_usuario.dart';
import 'package:projeto_estacionamento/pages/componentes/visual_formulario.dart';
import 'package:projeto_estacionamento/pages/inicio_page.dart';

/// Tela de login ligada ao backend: `UsuarioController.instancia.entrar(...)`.
///
/// Aceita e-mail ou telefone. As mensagens de erro ("E-mail ou senha
/// incorretos", "Sem conexão…", "Muitas tentativas…") já vêm prontas do
/// backend em `erro.mensagem`.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _ocultarSenha = true;
  bool _carregando = false;

  @override
  void dispose() {
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    if (_carregando || !_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);
    try {
      await UsuarioController.instancia.entrar(
        login: _loginController.text,
        senha: _senhaController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InicioPage()),
      );
    } on BackendException catch (erro) {
      if (mounted) mostrarMensagem(context, erro.mensagem, erro: true);
    } catch (_) {
      if (mounted) mostrarMensagem(context, CodigoErro.erroInterno.mensagemPadrao, erro: true);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirCadastro() async {
    // A tela de cadastro devolve o e-mail cadastrado quando dá certo.
    final emailCadastrado = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CadastroUsuario()),
    );
    if (emailCadastrado == null || !mounted) return;

    _loginController.text = emailCadastrado;
    _senhaController.clear();
    mostrarMensagem(context, 'Cadastro realizado! Digite sua senha para entrar.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.fundo,
      body: Stack(
        children: [
          const CabecalhoCurvo(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.local_parking, color: Colors.white, size: 44),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estacionamento Senac',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Entre para ver as vagas disponíveis',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 205, left: 16, right: 16, bottom: 30),
              child: Column(
                children: [
                  CartaoFormulario(
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          children: [
                            CampoFormulario(
                              titulo: 'E-mail ou telefone',
                              dica: 'Informe seu e-mail ou telefone',
                              icone: Icons.person_outline,
                              controller: _loginController,
                              teclado: TextInputType.emailAddress,
                              acaoTeclado: TextInputAction.next,
                              dicasPreenchimento: const [AutofillHints.username, AutofillHints.email],
                              habilitado: !_carregando,
                              validar: Validadores.login,
                            ),
                            CampoFormulario(
                              titulo: 'Senha',
                              dica: 'Informe sua senha',
                              icone: Icons.lock_outline,
                              controller: _senhaController,
                              senha: true,
                              ocultarSenha: _ocultarSenha,
                              aoAlternarSenha: () => setState(() => _ocultarSenha = !_ocultarSenha),
                              acaoTeclado: TextInputAction.done,
                              aoEnviar: (_) => _entrar(),
                              dicasPreenchimento: const [AutofillHints.password],
                              habilitado: !_carregando,
                              validar: Validadores.senhaLogin,
                            ),
                            const SizedBox(height: 20),
                            BotaoPrincipal(
                              texto: 'Entrar',
                              carregando: _carregando,
                              aoPressionar: _entrar,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Wrap: quebra a linha se a fonte do celular estiver grande.
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Não tem conta?', style: TextStyle(fontSize: 16)),
                      TextButton(
                        onPressed: _carregando ? null : _abrirCadastro,
                        style: TextButton.styleFrom(foregroundColor: CoresApp.laranja),
                        child: const Text(
                          'Cadastre-se',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
