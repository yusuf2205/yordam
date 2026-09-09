# Yordam

> Скажи, что нужно. Yordam поможет сделать.

Yordam — цифровой помощник реальной жизни: пользователь описывает задачу, а
приложение не просто отвечает, а доводит её до результата (план → задачи →
напоминания). Полное описание продукта, аудитории, ролей и roadmap — в
[`yordam.md`](./yordam.md).

## Структура репозитория

```text
yordam/
├── yordam.md          продуктовый и технический план
├── backend/           NestJS API (auth, tasks, AI-оркестрация)
├── mobile/             Flutter-приложение (Android, затем iOS)
└── docker-compose.yml  PostgreSQL + Redis для локальной разработки
```

## Быстрый старт (backend)

```bash
docker compose up -d          # Postgres + Redis
cd backend
cp .env.example .env          # заполнить ANTHROPIC_API_KEY и т.д.
npm install
npm run start:dev             # http://localhost:3000/api
```

Подробности и список эндпоинтов — в [`backend/README.md`](./backend/README.md).

## Быстрый старт (mobile)

Требует установленный Flutter SDK (не входит в этот репозиторий). Инструкция
и статус — в [`mobile/README.md`](./mobile/README.md).

## Статус — Sprint 1 (раздел 23 `yordam.md`)

| # | Задача | Статус |
| --- | --- | --- |
| 1 | Git-репозиторий | ✅ |
| 2 | Flutter-проект | ⚠️ Dart-код приложения готов (`mobile/lib`); нативные платформенные папки нужно сгенерировать `flutter create` — Flutter SDK не был доступен в среде разработки |
| 3 | NestJS backend | ✅ |
| 4 | PostgreSQL | ✅ подключение настроено (`docker-compose.yml` + TypeORM); контейнер не поднимался в этой среде (нет Docker) |
| 5 | Auth | ✅ регистрация/вход по телефону+паролю, JWT (упрощение вместо SMS OTP — см. `backend/README.md`) |
| 6 | Таблица `users` | ✅ |
| 7 | Главный экран | ✅ `mobile/lib/screens/home_screen.dart` — по мокапу из раздела 6 |
| 8 | AI chat | ✅ `mobile/lib/screens/ai_chat_screen.dart` + `POST /api/ai/chat` |
| 9 | Подключение AI API | ✅ Anthropic Claude, `backend/src/ai/ai.service.ts` |
| 10 | Первый AI-инструмент `create_task` | ✅ `backend/src/ai/tools/create-task.tool.ts` |

### Что нужно сделать перед первым реальным запуском

- Установить Flutter SDK и выполнить `flutter create` в `mobile/` (см.
  `mobile/README.md`).
- Установить Docker (или локальный PostgreSQL) и поднять базу.
- Получить `ANTHROPIC_API_KEY` и прописать в `backend/.env`.

### Осознанные упрощения MVP

- Аутентификация — телефон + пароль вместо SMS OTP из раздела 14 (нужен
  провайдер SMS; добавляется отдельно, структура auth-модуля это не
  усложнит).
- JWT на мобильном клиенте хранится в памяти, без persistent secure storage.
- В backend `synchronize: true` у TypeORM вместо миграций — нормально для
  MVP, требует замены на миграции до продакшена с реальными данными.
