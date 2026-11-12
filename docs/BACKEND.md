# Backend do app mobile (Login + Vagas)

O app fala **direto com o MySQL** usando o pacote `mysql_client_plus`. O banco é
o mesmo do projeto web (`estacionamentoSenac`), então **quem já tem conta no web
entra no app com a mesma senha**.

A tela só precisa de **um import**:

```dart
import 'package:projeto_estacionamento/features/features.dart';
```

---

## 1. Configurar e rodar

1. Copie `config/banco.example.json` para `config/banco.json` e preencha com os
   dados do banco (os mesmos nomes do `.env` do web).
   O `banco.json` está no `.gitignore`: **a senha não vai para o GitHub.**
2. Rode passando o arquivo:

```bash
flutter run --dart-define-from-file=config/banco.json
```

No VS Code, para o botão ▶ já usar o arquivo, crie `.vscode/launch.json`:

```json
{
  "configurations": [
    {
      "name": "App Estacionamento",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define-from-file=config/banco.json"]
    }
  ]
}
```

| Chave | O que é |
|---|---|
| `DB_HOST` | Endereço do banco. **No emulador Android, o PC é `10.0.2.2`** (não use `127.0.0.1`/`localhost`). No celular físico, use o IP do PC na rede (ex.: `192.168.0.15`) ou o host da nuvem. |
| `DB_PORT` | Porta (padrão 3306) |
| `DB_USER` / `DB_PASSWORD` | Usuário e senha do MySQL |
| `DB_NAME` | `estacionamentoSenac` |
| `DB_SSL` | `true` para banco na nuvem. Use `false` só para um MySQL local sem SSL. |
| `DB_SSL_ACEITAR_CERT_INVALIDO` | `true` = igual ao `rejectUnauthorized: false` do `db.js` do web. |

> Sem o `banco.json`, qualquer chamada lança `CodigoErro.configuracaoAusente`
> dizendo exatamente o que falta.

---

## 2. Login — `UsuarioController.instancia`

| Método | O que faz |
|---|---|
| `entrar(login:, senha:)` → `Usuario` | Login por **e-mail ou telefone** (com ou sem máscara). |
| `restaurarSessao()` → `Usuario?` | Chame ao abrir o app: devolve quem já estava logado (e confere no banco se a conta segue ativa). |
| `sair()` | Logout. |
| `usuarioAtual` / `estaLogado` | Quem está logado agora. |
| `usuarioLogado` | `ValueListenable<Usuario?>` para usar com `ValueListenableBuilder`. |
| `recarregarUsuario()` | Busca de novo os dados no banco. |

Regras (as mesmas do login do web):
- senha conferida com **bcrypt** (aceita os hashes que o web grava);
- "e-mail não existe" e "senha errada" dão **a mesma mensagem** (ninguém descobre quais e-mails estão cadastrados);
- conta com `ativo = 0` não entra;
- **5 erros seguidos bloqueiam por 30 segundos**;
- o bcrypt roda em outra thread: o `CircularProgressIndicator` não trava.

`Usuario` tem: `id`, `nome`, `primeiroNome`, `email`, `telefone`, `ativo`.

### Tela de login (o modelo do Firebase, trocado para o nosso backend)

Só mudam o `validator` dos campos e o `_entrar()`. O resto da tela continua igual.

```dart
Future<void> _entrar() async {
  if (!_formKey.currentState!.validate() || _carregando) return;
  setState(() => _carregando = true);

  try {
    await UsuarioController.instancia.entrar(
      login: _emailController.text,
      senha: _senhaController.text,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  } on BackendException catch (erro) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(erro.mensagem)));
    }
  } finally {
    if (mounted) setState(() => _carregando = false);
  }
}

// Nos campos:
TextFormField(controller: _emailController, validator: Validadores.login, ...)
TextFormField(controller: _senhaController, validator: Validadores.senhaLogin, ...)
```

Não precisa mais do `_mensagemDeErro(...)`: `erro.mensagem` já vem pronta
("E-mail ou senha incorretos", "Sem conexão com o servidor…", etc.).

### Manter logado ao abrir o app (`main.dart`)

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Usuario? usuario;
  try {
    usuario = await UsuarioController.instancia.restaurarSessao();
  } on BackendException {
    usuario = null; // qualquer problema: vai para o login
  }
  runApp(AppEstacionamento(logado: usuario != null));
}
// no MaterialApp: home: logado ? const HomePage() : const LoginPage(),
```

Botão de sair:

```dart
await UsuarioController.instancia.sair();
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
```

---

## 3. Vagas — `VagaController.instancia`

O app é **só para usuário comum**: aqui é **somente consulta** das vagas.
Cadastrar vaga e mudar ocupação continuam no web/sensores.

| Web | Mobile | Retorno |
|---|---|---|
| `GET /vagas` | `listarTodas()` | `List<Vaga>` |
| `GET /vagas/livres` | `listarLivres()` / `listarLivres(tipo: TipoVaga.idoso)` | `List<Vaga>` |
| `GET /vagas/total` | `resumo()` | `ResumoVagas` |
| `GET /vagas/:id` | `buscarPorId(id)` | `Vaga` |
| — | `observarVagas()` / `observarResumo()` | `Stream` que se atualiza sozinho |

> A rota `/vagas/registro/:id` do web (placa do carro que está na vaga) **não**
> existe no mobile de propósito: um usuário comum não pode ver a placa de outra
> pessoa.

**Modelos**

- `Vaga`: `id`, `codigo`, `tipo` (`TipoVaga.padrao/deficiente/idoso`, com `tipo.rotulo` = "PADRÃO"…), `ocupada`, `livre`, `statusTexto` ("LIVRE"/"OCUPADA").
- `ResumoVagas`: `total`, `ocupadas`, `livres`, `taxaOcupacao` (0–100), `taxaOcupacaoTexto` ("50%"), `ocupacaoTexto` ("2 de 4 vagas"), `lotado`.

### Grade de "bolinhas" que atualiza sozinha

O `observarVagas()` consulta o banco a cada 5 s, **só redesenha quando algo
mudou** (ex.: o sensor ocupou uma vaga) e para sozinho quando a tela fecha.

```dart
class _VagasPageState extends State<VagasPage> {
  late final _vagas = VagaController.instancia.observarVagas();   // cria UMA vez
  late final _resumo = VagaController.instancia.observarResumo();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      StreamBuilder<ResumoVagas>(
        stream: _resumo,
        builder: (context, s) => Text(
          s.hasData ? '${s.data!.livres} vagas livres' : '...',
          style: const TextStyle(fontSize: 24),
        ),
      ),
      Expanded(
        child: StreamBuilder<List<Vaga>>(
          stream: _vagas,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final erro = snapshot.error;
              return Center(child: Text(erro is BackendException ? erro.mensagem : 'Erro'));
            }
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            return GridView.count(
              crossAxisCount: 4,
              children: [
                for (final vaga in snapshot.data!)
                  Column(children: [
                    CircleAvatar(backgroundColor: vaga.ocupada ? Colors.red : Colors.green),
                    Text(vaga.codigo),
                    if (vaga.tipo.especial) Text(vaga.tipo.rotulo, style: const TextStyle(fontSize: 10)),
                  ]),
              ],
            );
          },
        ),
      ),
    ]);
  }
}
```

Lista simples só das livres (sem tempo real):

```dart
final livres = await VagaController.instancia.listarLivres();
```

---

## 4. Erros

Todo erro sai como `BackendException` com `.mensagem` pronta para mostrar e
`.codigo` para a tela decidir o que fazer:

| `CodigoErro` | Quando |
|---|---|
| `credenciaisInvalidas` | e-mail/telefone ou senha errados |
| `usuarioDesativado` | conta com `ativo = 0` |
| `muitasTentativas` | 5 erros seguidos (aguardar 30 s) |
| `naoAutenticado` | ação exige login → mande para a tela de login |
| `vagaNaoEncontrada` | id de vaga inexistente |
| `dadosInvalidos` | campo vazio/formato inválido |
| `semConexao` | sem internet / servidor fora do ar |
| `bancoIndisponivel` | banco recusou (usuário/senha do banco errados etc.) |
| `configuracaoAusente` | faltou o `--dart-define-from-file` |

A conexão se recupera sozinha: se a internet cair e voltar, ou o servidor
derrubar a conexão, a próxima consulta reconecta.

---

## 5. Segurança — leia antes de publicar o app

Como o app conecta direto no MySQL, **o usuário e a senha do banco vão dentro do
APK** (dá para extrair). Por isso **não use o `root` nem o usuário do web** no
app. Crie um usuário só para ele, que só pode o que o app faz:

```sql
CREATE USER 'app_mobile'@'%' IDENTIFIED BY 'uma_senha_forte_aqui';
GRANT SELECT ON estacionamentoSenac.tbl_usuario TO 'app_mobile'@'%';
GRANT SELECT ON estacionamentoSenac.tbl_vaga    TO 'app_mobile'@'%';
FLUSH PRIVILEGES;
```

(Quando entrarem veículo, pagamento e editar dados, esse usuário vai precisar
de mais permissões nessas tabelas — dar só as que cada função usar.)

Mesmo assim, quem extrair essa senha consegue ler a `tbl_usuario` (com os hashes
bcrypt). Para um app em produção de verdade, o certo é o app chamar uma API (como
o backend do web) em vez do banco. Para o projeto da disciplina, o usuário
limitado acima é o recomendado.

Outros cuidados já tratados no código:
- todo SQL usa parâmetros (`:id`), nunca texto concatenado → sem SQL Injection;
- a senha do usuário nunca sai do repository e nunca é salva no celular;
- a sessão salva no celular guarda só id, nome, e-mail, telefone e cargo.

---

## 6. Estrutura das pastas

```
lib/
├── core/                                  ← o que todas as features usam
│   ├── config/banco_config.dart           ← lê o config/banco.json   (.env do web)
│   ├── conexao/banco_mysql.dart           ← pool + reconexão + erros (Connection/db.js)
│   ├── conexao/executor_sql.dart          ← contrato do banco (permite testar sem MySQL)
│   ├── erros/backend_exception.dart       ← CodigoErro + BackendException
│   └── utils/
│       ├── validadores.dart               ← regras de campo (tela e backend usam as mesmas)
│       └── conversao.dart                 ← texto do MySQL → int/bool/DateTime…
│
├── features/
│   ├── features.dart                      ← o único import que as telas usam
│   ├── usuarios/
│   │   ├── controllers/usuario_controller.dart   ← login, sessão, logout
│   │   ├── repositories/usuario_repository.dart  ← SQL da tbl_usuario
│   │   ├── repositories/armazenamento_sessao.dart← sessão salva no celular
│   │   └── models/usuario.dart
│   └── vagas/
│       ├── controllers/vaga_controller.dart      ← vagas disponíveis + tempo real
│       ├── repositories/vaga_repository.dart     ← SQL da tbl_vaga
│       └── models/vaga.dart, resumo_vagas.dart
│
├── pages/                                 ← telas (front)
└── main.dart
```

O caminho de uma chamada é sempre:
`page → controller (regras) → repository (SQL) → core/conexao → MySQL`

Nova funcionalidade (ex.: veículos)? Crie `features/veiculos/` com as mesmas
três pastas e exporte o controller e os models no `features/features.dart`.

Testes: `flutter test test/features` (rodam sem banco, com um banco falso).

Tabelas usadas: `tbl_usuario` (`id, nome_usuario, email, numero_usuario, senha,
cargo, ativo`) e `tbl_vaga` — conforme o
`Backend/Database/estacionamentoSenac.sql` do web.
