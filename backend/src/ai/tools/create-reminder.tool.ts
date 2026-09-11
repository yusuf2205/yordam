import { Injectable } from '@nestjs/common';
import { RemindersService } from '../../reminders/reminders.service.js';
import type { AiTool } from './ai-tool.interface.js';

export interface CreateReminderToolInput {
  title: string;
  remind_at: string;
  timezone?: string;
}

/**
 * Turns "Завтра в 10 утра напомни мне позвонить поставщику" into a real row
 * in the reminders table (Phase 3, section 16 of yordam.md), instead of a
 * text-only reply. Actual notification delivery is Phase 4 — this tool only
 * persists the reminder itself.
 */
@Injectable()
export class CreateReminderTool implements AiTool<CreateReminderToolInput> {
  readonly name = 'create_reminder';
  readonly description =
    'Создаёт напоминание пользователя в Yordam на конкретную дату и время. ' +
    'Используй, когда пользователь просит напомнить о чём-то в определённый момент времени ' +
    '(например "напомни завтра в 10 позвонить поставщику"). Обязательно определи точную ' +
    'дату и время в ISO 8601 на основе текущего момента и того, что сказал пользователь.';
  readonly inputSchema = {
    type: 'object',
    properties: {
      title: {
        type: 'string',
        description: 'Короткое описание, о чём напомнить.',
      },
      remind_at: {
        type: 'string',
        description: 'Дата и время напоминания в формате ISO 8601 (с таймзоной).',
      },
      timezone: {
        type: 'string',
        description: 'IANA-таймзона пользователя, например Asia/Tashkent. По умолчанию Asia/Tashkent.',
      },
    },
    required: ['title', 'remind_at'],
  };

  constructor(private readonly remindersService: RemindersService) {}

  async execute(userId: string, input: CreateReminderToolInput) {
    const reminder = await this.remindersService.create(userId, {
      title: input.title,
      remindAt: input.remind_at,
      timezone: input.timezone,
    });
    return reminder;
  }
}
