import 'dotenv/config';
import { DataSource } from 'typeorm';
import { User } from './users/entities/user.entity.js';
import { Task } from './tasks/entities/task.entity.js';
import { AiConversation } from './ai/entities/ai-conversation.entity.js';
import { AiMessage } from './ai/entities/ai-message.entity.js';

// Standalone DataSource for the TypeORM CLI (migration:generate / :run /
// :revert — see package.json scripts). Not used by the running app itself;
// AppModule configures its own connection via TypeOrmModule.forRootAsync.
export default new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST ?? 'localhost',
  port: Number(process.env.DB_PORT ?? 5432),
  username: process.env.DB_USER ?? 'yordam',
  password: process.env.DB_PASSWORD ?? 'yordam',
  database: process.env.DB_NAME ?? 'yordam',
  entities: [User, Task, AiConversation, AiMessage],
  migrations: ['src/migrations/*.ts'],
});
