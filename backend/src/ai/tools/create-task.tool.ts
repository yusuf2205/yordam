import { Injectable } from '@nestjs/common';
import { TasksService } from '../../tasks/tasks.service.js';
import { TaskPriority } from '../../tasks/entities/task.entity.js';
import type { AiTool } from './ai-tool.interface.js';

export interface CreateTaskToolInput {
  title: string;
  description?: string;
  priority?: TaskPriority;
  due_date?: string;
}

/**
 * The first AI tool from Sprint 1 (section 23, item 10): lets the model turn
 * a message like "Завтра в 10 утра позвонить поставщику" into a real row in
 * the tasks table instead of just replying in text.
 */
@Injectable()
export class CreateTaskTool implements AiTool<CreateTaskToolInput> {
  readonly name = 'create_task';
  readonly description =
    'Создаёт задачу пользователя в Yordam. Используй, когда пользователь просит ' +
    'что-то сделать, напомнить сделать или явно формулирует дело/поручение.';
  readonly inputSchema = {
    type: 'object',
    properties: {
      title: {
        type: 'string',
        description: 'Короткое название задачи, понятное пользователю.',
      },
      description: {
        type: 'string',
        description: 'Дополнительные детали задачи, если они есть.',
      },
      priority: {
        type: 'string',
        enum: Object.values(TaskPriority),
        description: 'Приоритет задачи. По умолчанию — medium.',
      },
      due_date: {
        type: 'string',
        description: 'Срок выполнения задачи в формате ISO 8601, если указан.',
      },
    },
    required: ['title'],
  };

  constructor(private readonly tasksService: TasksService) {}

  async execute(userId: string, input: CreateTaskToolInput) {
    const task = await this.tasksService.create(
      userId,
      {
        title: input.title,
        description: input.description,
        priority: input.priority,
        dueDate: input.due_date,
      },
      { createdByAi: true },
    );
    return task;
  }
}
