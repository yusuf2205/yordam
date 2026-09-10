# Yordam — Mobile (Flutter)

## Статус

Flutter SDK не был установлен в окружении, где писался этот код, поэтому здесь
лежит только Dart-код приложения (`pubspec.yaml` + `lib/`) — **без**
сгенерированных платформенных папок `android/`, `ios/` и т.д. Их создаёт сам
Flutter, и вручную их надёжно не воспроизвести.

## Как поднять проект локально

1. Установите Flutter SDK: https://docs.flutter.dev/get-started/install
2. Проверьте окружение:

   ```bash
   flutter doctor
   ```

3. В этой папке (`mobile/`) сгенерируйте недостающие платформенные файлы —
   команда не тронет уже существующие `pubspec.yaml` и `lib/`:

   ```bash
   cd mobile
   flutter create --org uz.yordam --platforms=android .
   ```

   (добавьте `,ios` к `--platforms`, когда дойдёте до iOS — см. раздел 12
   `yordam.md`).

4. Установите зависимости и запустите:

   ```bash
   flutter pub get
   flutter run
   ```

## Что уже реализовано

- `lib/main.dart` — точка входа, тема.
- `lib/screens/login_screen.dart` — регистрация/вход по телефону и паролю.
- `lib/screens/home_screen.dart` — главный экран по мокапу из раздела 6
  `yordam.md`: приветствие, поле «Чем помочь?», быстрый доступ к модулям.
- `lib/screens/ai_chat_screen.dart` — чат с AI-помощником, дергает
  `POST /api/ai/chat` на backend; если AI вызвал инструмент `create_task`,
  в ответе показывается счётчик созданных задач.
- `lib/screens/tasks_screen.dart` — список задач пользователя.
- `lib/services/api_client.dart` — тонкий клиент backend REST API.

## Известные упрощения (для следующих спринтов)

- JWT-токен хранится только в памяти (сбрасывается при перезапуске
  приложения) — до подключения `flutter_secure_storage`.
- `ApiClient.baseUrl` захардкожен на `http://mynas.tail4bf75c.ts.net:3005/api`
  (backend на NAS пользователя, доступен по Tailscale). Для реального
  устройства нужен Tailscale в том же tailnet-е; для прод-домена — вынести
  в конфиг/переменные окружения (`--dart-define`).
- Голосовой ввод (иконка микрофона на главном экране) — заглушка, без
  реальной интеграции speech-to-text.
