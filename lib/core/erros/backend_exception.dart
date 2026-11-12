/// Todos os erros que o backend pode devolver para a tela.
///
/// A mensagem padrão já está pronta para mostrar ao usuário (SnackBar, alerta…).
/// O código serve para a tela tomar decisões, por exemplo:
///   if (erro.codigo == CodigoErro.naoAutenticado) -> voltar para o login
enum CodigoErro {
  // ---- Login ----
  credenciaisInvalidas('E-mail ou senha incorretos'),
  usuarioDesativado('Conta desativada. Procure a administração'),
  muitasTentativas('Muitas tentativas. Aguarde um pouco e tente novamente'),
  naoAutenticado('Você precisa estar logado para continuar'),

  // ---- Vagas ----
  vagaNaoEncontrada('Vaga não encontrada'),

  // ---- Gerais ----
  dadosInvalidos('Dados inválidos'),
  registroDuplicado('Esse registro já existe'),
  semConexao('Sem conexão com o servidor. Verifique sua internet'),
  bancoIndisponivel('Não foi possível acessar o banco de dados'),
  configuracaoAusente('O app não está configurado para acessar o banco'),
  erroInterno('Ocorreu um erro inesperado. Tente novamente');

  final String mensagemPadrao;
  const CodigoErro(this.mensagemPadrao);
}

class BackendException implements Exception {
  final CodigoErro codigo;
  final String mensagem;

  /// Erro original (do MySQL, da rede…). Útil para depurar, nunca para mostrar ao usuário.
  final Object? causa;

  BackendException(this.codigo, {String? mensagem, this.causa})
      : mensagem = mensagem ?? codigo.mensagemPadrao;

  @override
  String toString() => 'BackendException(${codigo.name}): $mensagem';
}
