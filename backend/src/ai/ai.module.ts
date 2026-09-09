import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiConversation } from './entities/ai-conversation.entity.js';
import { AiMessage } from './entities/ai-message.entity.js';
import { AiService } from './ai.service.js';
import { AiController } from './ai.controller.js';
import { CreateTaskTool } from './tools/create-task.tool.js';
import { TasksModule } from '../tasks/tasks.module.js';

@Module({
  imports: [TypeOrmModule.forFeature([AiConversation, AiMessage]), TasksModule],
  providers: [AiService, CreateTaskTool],
  controllers: [AiController],
})
export class AiModule {}
