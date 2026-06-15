# Projeto Integrador Mobile

Aplicativo Flutter mobile com MVVM e Clean Architecture para login de cliente e motorista.

## Backend

Por padrão o app usa `http://10.0.2.2:3000/api`.

Para apontar para outro backend, rode com:

```bash
flutter run --dart-define=API_BASE_URL=http://SEU_HOST:3000/api
```

## Estrutura

- `lib/core`: config, network e storage
- `lib/features/auth`: login, domínio e dados
- `lib/features/client`: home do cliente
- `lib/features/driver`: home do motorista