# Backend do app mobile (Login + Cadastro + Vagas)

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

### Tela de login — `lib/pages/login_page.dart` (já ligada)

A tela de login já chama o backend. O que ela faz:

```dart
Future<void> _entrar() async {
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
  } finally {
    if (mounted) setState(() => _carregando = false);
  }
}

// Nos campos:
CampoFormulario(controller: _loginController, validator: Validadores.login, ...)
CampoFormulario(controller: _senhaController, validator: Validadores.senhaLogin, ...)
```

Não precisa de `_mensagemDeErro(...)`: `erro.mensagem` já vem pronta
("E-mail ou senha incorretos", "Sem conexão com o servidor…", etc.).

O link **"Não tem conta? Cadastre-se"** abre o cadastro. Quando o cadastro dá
certo, a tela de cadastro fecha devolvendo o e-mail, e o login já aparece com
o e-mail preenchido e a mensagem "Cadastro realizado!".

Depois do login o app vai para `lib/pages/inicio_page.dart`, uma tela
**provisória** (nome do usuário + vagas livres em tempo real + botão Sair).
Quando a Home do time existir, troque `InicioPage` por ela em `login_page.dart`
e `main.dart`.

### Manter logado ao abrir o app (`main.dart`, já feito)

A primeira tela é a `TelaAbertura`: ela chama `restaurarSessao()` mostrando um
carregando e vai para o início (se já estava logado) ou para o login. Qualquer
erro (banco fora do ar, faltou o `banco.json`…) leva para o login.

Botão de sair (já está na `InicioPage`):

```dart
await UsuarioController.instancia.sair();
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
```

---

## 3. Cadastro — `UsuarioController.instancia.cadastrar(...)`

É o `criar` do `usuarioController.js` do web (`POST /usuarios`), mesma tabela.

| Web (`POST /usuarios`) | Mobile |
|---|---|
| body `{ nome_usuario, email, numero_usuario, senha }` | `cadastrar(nome:, email:, telefone:, senha:)` → `Usuario` |
| 400 "Nome, e-mail e senha são obrigatórios" | `CodigoErro.dadosInvalidos` com a mensagem do campo |
| 400 "A senha deve ter no mínimo 6 caracteres" | idem (mesma regra: mínimo 6) |
| 409 "Este e-mail já está em uso." | `CodigoErro.emailEmUso` |
| — (o banco recusava com erro 500) | `CodigoErro.telefoneEmUso` (`numero_usuario` também é UNIQUE) |
| `bcrypt.hash(senha, ...)` | bcrypt **custo 12** (o `CUSTO_BCRYPT` do login do web), em outra thread |
| 201 `{ id_usuario }` | devolve o `Usuario` criado (com o `id`) |

Regras:
- nome, e-mail e senha obrigatórios; telefone **opcional no backend** (como no
  web) — a tela exige com `Validadores.telefone`;
- nome: espaços extras são removidos, máximo 120 caracteres (`VARCHAR(120)`);
- e-mail: gravado em minúsculo, máximo 120;
- telefone: com DDD (10 ou 11 dígitos), gravado **só com os números**
  (`11988887777`), que é como o login por telefone procura;
- senha: mínimo 6, máximo 72 (limite do bcrypt), gravada só como hash;
- **o app nunca envia o `cargo`**: todo cadastro feito no celular é `usuario`
  (o DEFAULT da tabela). Administrador só se cria pelo web;
- o cadastro **não faz login sozinho** — igual ao web, volta para o login;
- se duas pessoas cadastrarem o mesmo e-mail no mesmo instante, o UNIQUE do
  banco barra a segunda e ela recebe "Este e-mail já está em uso".

### Tela de cadastro — `lib/pages/cadastro_usuario.dart` (já ligada)

É a tela da branch `telaDeCadastroDeUsuario` (mesmo visual laranja), agora
gravando no banco:

```dart
Future<void> salvarUsuario() async {
  if (carregando || !formKey.currentState!.validate()) return;
  setState(() => carregando = true);
  try {
    final usuario = await UsuarioController.instancia.cadastrar(
      nome: nomeController.text,
      email: emailController.text,
      telefone: telefoneController.text, // pode vir com a máscara
      senha: senhaController.text,
    );
    if (!mounted) return;
    Navigator.of(context).pop(usuario.email); // volta para o login
  } on BackendException catch (erro) {
    if (mounted) mostrarMensagem(context, erro.mensagem, erro: true);
  } finally {
    if (mounted) setState(() => carregando = false);
  }
}
```

Validadores dos campos: `Validadores.nome`, `Validadores.email`,
`Validadores.telefone`, `Validadores.senhaCadastro` (as mesmas regras que o
backend confere).

As duas telas usam os componentes de `lib/pages/componentes/visual_formulario.dart`
(`CabecalhoCurvo`, `CartaoFormulario`, `CampoFormulario`, `BotaoPrincipal`,
`mostrarMensagem`, `CoresApp`) — use-os nas próximas telas para manter o visual.

---

## 4. Vagas — `VagaController.instancia`

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

## 5. Erros

Todo erro sai como `BackendException` com `.mensagem` pronta para mostrar e
`.codigo` para a tela decidir o que fazer:

| `CodigoErro` | Quando |
|---|---|
| `credenciaisInvalidas` | e-mail/telefone ou senha errados |
| `usuarioDesativado` | conta com `ativo = 0` |
| `muitasTentativas` | 5 erros seguidos (aguardar 30 s) |
| `naoAutenticado` | ação exige login → mande para a tela de login |
| `emailEmUso` | cadastro com e-mail que já existe |
| `telefoneEmUso` | cadastro com telefone que já existe |
| `vagaNaoEncontrada` | id de vaga inexistente |
| `dadosInvalidos` | campo vazio/formato inválido |
| `registroDuplicado` | o banco recusou um valor repetido (UNIQUE) |
| `semConexao` | sem internet / servidor fora do ar |
| `bancoIndisponivel` | banco recusou (usuário/senha do banco errados etc.) |
| `configuracaoAusente` | faltou o `--dart-define-from-file` |

A conexão se recupera sozinha: se a internet cair e voltar, ou o servidor
derrubar a conexão, a próxima consulta reconecta.

---

## 6. Segurança — leia antes de publicar o app

Como o app conecta direto no MySQL, **o usuário e a senha do banco vão dentro do
APK** (dá para extrair). Por isso **não use o `root` nem o usuário do web** no
app. Crie um usuário só para ele, que só pode o que o app faz:

```sql
CREATE USER 'app_mobile'@'%' IDENTIFIED BY 'uma_senha_forte_aqui';
GRANT SELECT ON estacionamentoSenac.tbl_usuario TO 'app_mobile'@'%';
GRANT SELECT ON estacionamentoSenac.tbl_vaga    TO 'app_mobile'@'%';
-- Cadastro: INSERT só nestas 4 colunas. Sem permissão na coluna "cargo",
-- o banco sempre usa o DEFAULT 'usuario' -> ninguém cria administrador pelo app.
GRANT INSERT (nome_usuario, email, numero_usuario, senha)
  ON estacionamentoSenac.tbl_usuario TO 'app_mobile'@'%';
FLUSH PRIVILEGES;
```

Se o usuário `app_mobile` já existe, rode só o `GRANT INSERT (...)` e o `FLUSH`.
Sem ele, o cadastro falha com "Não foi possível acessar o banco de dados".

(Quando entrarem veículo, pagamento e editar dados, esse usuário vai precisar
de mais permissões nessas tabelas — dar só as que cada função usar.)

Mesmo assim, quem extrair essa senha consegue ler a `tbl_usuario` (com os hashes
bcrypt) e criar contas comuns. Para um app em produção de verdade, o certo é o
app chamar uma API (como o backend do web) em vez do banco. Para o projeto da
disciplina, o usuário limitado acima é o recomendado.

Outros cuidados já tratados no código:
- todo SQL usa parâmetros (`:id`), nunca texto concatenado → sem SQL Injection;
- a senha do usuário nunca sai do repository e nunca é salva no celular;
- a sessão salva no celular guarda só id, nome, e-mail, telefone e cargo;
- o cadastro nunca envia `cargo` (sempre usuário comum).

---

## 7. Estrutura das pastas

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
│   │   ├── controllers/usuario_controller.dart   ← login, cadastro, sessão, logout
│   │   ├── repositories/usuario_repository.dart  ← SQL da tbl_usuario
│   │   ├── repositories/armazenamento_sessao.dart← sessão salva no celular
│   │   └── models/usuario.dart
│   └── vagas/
│       ├── controllers/vaga_controller.dart      ← vagas disponíveis + tempo real
│       ├── repositories/vaga_repository.dart     ← SQL da tbl_vaga
│       └── models/vaga.dart, resumo_vagas.dart
│
├── pages/                                 ← telas (front)
│   ├── login_page.dart                    ← login (ligado ao backend)
│   ├── cadastro_usuario.dart              ← cadastro (ligado ao backend)
│   ├── inicio_page.dart                   ← tela provisória pós-login
│   └── componentes/visual_formulario.dart ← cabeçalho, campos e botão laranja
└── main.dart                              ← abre no login ou já logado
```

O caminho de uma chamada é sempre:
`page → controller (regras) → repository (SQL) → core/conexao → MySQL`

Nova funcionalidade (ex.: veículos)? Crie `features/veiculos/` com as mesmas
três pastas e exporte o controller e os models no `features/features.dart`.

Testes: `flutter test` (rodam sem banco, com um banco falso; o
`test/widget_test.dart` testa as telas de login e cadastro).

Tabelas usadas: `tbl_usuario` (`id, nome_usuario, email, numero_usuario, senha,
cargo, ativo`) e `tbl_vaga` — conforme o
`Backend/Database/estacionamentoSenac.sql` do web.
