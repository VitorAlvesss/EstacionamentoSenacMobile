Parte mobile do projeto do estacionamento.

## Backend (login e vagas)

O backend fica em `lib/core/` e `lib/features/` (usuarios e vagas) e conecta direto no MySQL do projeto web.

1. Copie `config/banco.example.json` para `config/banco.json` e preencha.
2. `flutter run --dart-define-from-file=config/banco.json`

Como usar nas telas: [docs/BACKEND.md](docs/BACKEND.md)
