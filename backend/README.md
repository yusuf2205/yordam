# Yordam — Backend (NestJS)

REST API for Yordam. See `../yordam.md` for the full product plan and
`../README.md` for the repo-wide overview.

## Stack

- NestJS 12 (TypeScript, ESM/NodeNext)
- PostgreSQL via TypeORM
- JWT auth (`@nestjs/passport` + `passport-jwt`)
- Anthropic Claude for the AI orchestration layer (`src/ai`)

## Modules implemented (Sprint 1)

- `users` — `User` entity (phone, name, email, language, timezone).
- `auth` — register/login by phone + password, returns a JWT. (Section 14 of
  the plan calls for phone OTP login; that needs an SMS provider integration
  and is a follow-up — password auth ships now so the rest of the stack is
  usable end-to-end.)
- `tasks` — CRUD for tasks, scoped to the authenticated user.
- `ai` — orchestration layer per section 16 of the plan: takes a user
  message, calls Claude with a registered tool set, executes any tool calls
  (currently `create_task`), and returns the reply plus what was created.
  New tools (`create_reminder`, `create_purchase`, `save_document`,
  `add_expense`, ...) implement `AiTool` in `src/ai/tools/` and get added to
  the list in `AiModule` — `AiService`'s loop doesn't change.

## Getting started

1. Start Postgres (and Redis, for later use) from the repo root:

   ```bash
   docker compose up -d
   ```

2. Copy the env file and fill in secrets:

   ```bash
   cp .env.example .env
   # set ANTHROPIC_API_KEY to enable the AI chat endpoint
   ```

3. Install dependencies and run:

   ```bash
   npm install
   npm run start:dev
   ```

   The API listens on `http://localhost:3000/api`. `synchronize: true` is on
   in development, so TypeORM creates the tables from the entities
   automatically — no migrations to run yet.

## Key endpoints

| Method | Path                | Auth | Description                              |
| ------ | ------------------- | ---- | ----------------------------------------- |
| POST   | `/api/auth/register` | —    | Create an account (phone + password)      |
| POST   | `/api/auth/login`    | —    | Get a JWT                                 |
| GET    | `/api/tasks`          | JWT  | List the current user's tasks             |
| POST   | `/api/tasks`          | JWT  | Create a task directly                    |
| PATCH  | `/api/tasks/:id`      | JWT  | Update a task                             |
| DELETE | `/api/tasks/:id`      | JWT  | Delete a task                             |
| POST   | `/api/ai/chat`        | JWT  | Send a message to the AI assistant        |

## Scripts

- `npm run start:dev` — dev server with watch mode
- `npm run build` — compile to `dist/`
- `npm run test` — unit tests (vitest)
- `npm run test:e2e` — e2e tests (vitest)
- `npm run lint` — oxlint
