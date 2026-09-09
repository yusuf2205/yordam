import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiConversation } from './entities/ai-conversation.entity.js';
import { AiMessage } from './entities/ai-message.entity.js';
import { AiService } from './ai.service.js';
import { AiController } from './ai.controller.js';
import { CreateTaskTool } from './tools/create-task.tool.js';
import { TasksModule } from '../tasks/tasks.module.js';
import { AuthModule } from '../auth/auth.module.js';

@Module({
  // AuthModule for PassportModule — AiController guards routes with
  // JwtAuthGuard (see auth/auth.module.ts for why this is needed). Note
  // TasksModule importing AuthModule doesn't re-export it, so AiModule needs
  // its own import too.
  imports: [TypeOrmModule.forFeature([AiConversation, AiMessage]), TasksModule, AuthModule],
  providers: [AiService, CreateTaskTool],
  controllers: [AiController],
})
export class AiModule {}
