import { Injectable } from '@nestjs/common';
import { CalendarService } from '../../calendar/calendar.service.js';
import type { AiTool } from './ai-tool.interface.js';

export interface CreateCalendarEventToolInput {
  title: string;
  start_at: string;
  end_at?: string;
  location?: string;
  description?: string;
  reminder_minutes?: number;
  timezone?: string;
}

/**
 * Turns "В понедельник в 15:00 встреча с Ахмедом в офисе, напомни за час" into
 * a real calendar_events row (Phase 5, section 13 of yordam.md), optionally
 * with a linked reminder created automatically by CalendarService.
 */
@Injectable()
export class CreateCalendarEventTool implements AiTool<CreateCalendarEventToolInput> {
  readonly name = 'create_calendar_event';
  readonly description =
    'Создаёт событие в календаре пользователя (встречу, приём и т.п.) на конкретную дату и ' +
    'время. Используй, когда пользователь описывает встречу/событие с конкретным временем. ' +
    'Если пользователь просит напомнить заранее — заполни reminder_minutes.';
  readonly inputSchema = {
    type: 'object',
    properties: {
      title: {
        type: 'string',
        description: 'Название события, например "Встреча с Ахмедом".',
      },
      start_at: {
        type: 'string',
        description: 'Дата и время начала события в формате ISO 8601 (с таймзоной).',
      },
      end_at: {
        type: 'string',
        description: 'Дата и время окончания, если известны, в формате ISO 8601.',
      },
      location: {
        type: 'string',
        description: 'Место проведения, если указано.',
      },
      description: {
        type: 'string',
        description: 'Дополнительные детали события, если есть.',
      },
      reminder_minutes: {
        type: 'number',
        description: 'За сколько минут до события напомнить, если пользователь просил.',
      },
      timezone: {
        type: 'string',
        description: 'IANA-таймзона пользователя, например Asia/Tashkent. По умолчанию Asia/Tashkent.',
      },
    },
    required: ['title', 'start_at'],
  };

  constructor(private readonly calendarService: CalendarService) {}

  async execute(userId: string, input: CreateCalendarEventToolInput) {
    return this.calendarService.create(userId, {
      title: input.title,
      description: input.description,
      location: input.location,
      startAt: input.start_at,
      endAt: input.end_at,
      timezone: input.timezone,
      reminderMinutes: input.reminder_minutes,
    });
  }
}
