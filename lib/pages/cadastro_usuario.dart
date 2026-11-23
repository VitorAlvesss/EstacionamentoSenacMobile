import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'package:projeto_estacionamento/features/features.dart';
import 'package:projeto_estacionamento/pages/componentes/visual_formulario.dart';

/// Tela de cadastro de usuário (layout da branch telaDeCadastroDeUsuario),
/// ligada ao backend: `UsuarioController.instancia.cadastrar(...)`.
///
/// Ao cadastrar, volta para a tela anterior (o login) devolvendo o e-mail
/// cadastrado, para o login já vir preenchido — igual ao web, que manda para
/// o login depois do cadastro.
class CadastroUsuario extends StatefulWidget {
  const CadastroUsuario({super.key});

  @override
  State<CadastroUsuario> createState() => _CadastroUsuarioState();
}

class _CadastroUsuarioState extends State<CadastroUsuario> {
  final formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final senhaController = TextEditingController();

  bool ocultarSenha = true;
  bool carregando = false;

  final telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // Método salvar cadastro
  Future<void> salvarUsuario() async {
    FocusScope.of(context).unfocus();
    if (carregando || !formKey.currentState!.validate()) return;

    setState(() => carregando = true);
    try {
      final usuario = await UsuarioController.instancia.cadastrar(
        nome: nomeController.text,
        email: emailController.text,
        telefone: telefoneController.text,
        senha: senhaController.text,
      );
      if (!mounted) return;

      final navegador = Navigator.of(context);
      if (navegador.canPop()) {
        navegador.pop(usuario.email); // o login mostra a mensagem de sucesso
      } else {
        mostrarMensagem(context, 'Cadastro realizado com sucesso!');
        formKey.currentState!.reset();
        for (final campo in [nomeController, emailController, telefoneController, senhaController]) {
          campo.clear();
        }
      }
    } on BackendException catch (erro) {
      if (mounted) mostrarMensagem(context, erro.mensagem, erro: true);
    } catch (_) {
      if (mounted) mostrarMensagem(context, CodigoErro.erroInterno.mensagemPadrao, erro: true);
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.fundo,
      body: Stack(
        children: [
          // Cabeçalho (a seta de voltar fica numa camada por cima, lá embaixo)
          const CabecalhoCurvo(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 56), // espaço da seta de voltar
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'Cadastro',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Formulário
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 205, left: 16, right: 16, bottom: 30),
              child: CartaoFormulario(
                child: Form(
                  key: formKey,
                  child: AutofillGroup(
                    child: Column(
                      children: [
                        // Nome
                        CampoFormulario(
                          titulo: 'Nome',
                          dica: 'Informe seu nome completo',
                          icone: Icons.person_outline,
                          controller: nomeController,
                          teclado: TextInputType.name,
                          acaoTeclado: TextInputAction.next,
                          dicasPreenchimento: const [AutofillHints.name],
                          habilitado: !carregando,
                          validar: Validadores.nome,
                        ),

                        // E-mail
                        CampoFormulario(
                          titulo: 'E-mail',
                          dica: 'Informe seu e-mail',
                          icone: Icons.email_outlined,
                          controller: emailController,
                          teclado: TextInputType.emailAddress,
                          acaoTeclado: TextInputAction.next,
                          dicasPreenchimento: const [AutofillHints.email],
                          habilitado: !carregando,
                          validar: Validadores.email,
                        ),

                        // Telefone
                        CampoFormulario(
                          titulo: 'Telefone',
                          dica: '(00) 00000-0000',
                          icone: Icons.phone_outlined,
                          controller: telefoneController,
                          teclado: TextInputType.phone,
                          formatadores: [telefoneMask],
                          acaoTeclado: TextInputAction.next,
                          dicasPreenchimento: const [AutofillHints.telephoneNumber],
                          habilitado: !carregando,
                          validar: Validadores.telefone,
                        ),

                        // Senha
                        CampoFormulario(
                          titulo: 'Senha',
                          dica: 'Crie uma senha',
                          icone: Icons.lock_outline,
                          controller: senhaController,
                          senha: true,
                          ocultarSenha: ocultarSenha,
                          aoAlternarSenha: () => setState(() => ocultarSenha = !ocultarSenha),
                          acaoTeclado: TextInputAction.done,
                          aoEnviar: (_) => salvarUsuario(),
                          dicasPreenchimento: const [AutofillHints.newPassword],
                          habilitado: !carregando,
                          validar: Validadores.senhaCadastro,
                        ),

                        const SizedBox(height: 20),

                        // Botão cadastrar
                        BotaoPrincipal(
                          texto: 'Cadastrar',
                          carregando: carregando,
                          aoPressionar: salvarUsuario,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Seta de voltar: por último no Stack para ficar POR CIMA da área
          // rolável — senão a lista "engole" o toque e a seta não funciona.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: IconButton(
                onPressed: carregando ? null : () => Navigator.maybePop(context),
                tooltip: 'Voltar',
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
