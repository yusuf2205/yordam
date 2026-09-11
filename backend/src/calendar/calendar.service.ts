import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CalendarEvent } from './entities/calendar-event.entity.js';
import { CreateCalendarEventDto } from './dto/create-calendar-event.dto.js';
import { UpdateCalendarEventDto } from './dto/update-calendar-event.dto.js';
import { RemindersService } from '../reminders/reminders.service.js';

@Injectable()
export class CalendarService {
  constructor(
    @InjectRepository(CalendarEvent)
    private readonly eventsRepository: Repository<CalendarEvent>,
    private readonly remindersService: RemindersService,
  ) {}

  findAllForUser(userId: string): Promise<CalendarEvent[]> {
    return this.eventsRepository.find({
      where: { userId },
      order: { startAt: 'ASC' },
    });
  }

  async findOneForUser(userId: string, id: string): Promise<CalendarEvent> {
    const event = await this.eventsRepository.findOne({ where: { id, userId } });
    if (!event) {
      throw new NotFoundException(`Calendar event ${id} not found`);
    }
    return event;
  }

  async create(userId: string, dto: CreateCalendarEventDto): Promise<CalendarEvent> {
    const event = this.eventsRepository.create({
      title: dto.title,
      description: dto.description,
      location: dto.location,
      startAt: new Date(dto.startAt),
      endAt: dto.endAt ? new Date(dto.endAt) : undefined,
      timezone: dto.timezone,
      reminderMinutes: dto.reminderMinutes,
      userId,
    });
    const saved = await this.eventsRepository.save(event);

    if (dto.reminderMinutes !== undefined) {
      await this.remindersService.create(
        userId,
        {
          title: `Встреча: ${saved.title}`,
          remindAt: new Date(saved.startAt.getTime() - dto.reminderMinutes * 60_000).toISOString(),
          timezone: saved.timezone,
        },
        { calendarEventId: saved.id },
      );
    }

    return saved;
  }

  async update(userId: string, id: string, dto: UpdateCalendarEventDto): Promise<CalendarEvent> {
    const event = await this.findOneForUser(userId, id);
    if (dto.title !== undefined) event.title = dto.title;
    if (dto.description !== undefined) event.description = dto.description;
    if (dto.location !== undefined) event.location = dto.location;
    if (dto.startAt !== undefined) event.startAt = new Date(dto.startAt);
    if (dto.endAt !== undefined) event.endAt = new Date(dto.endAt);
    if (dto.timezone !== undefined) event.timezone = dto.timezone;
    if (dto.reminderMinutes !== undefined) event.reminderMinutes = dto.reminderMinutes;
    if (dto.status !== undefined) event.status = dto.status;
    const saved = await this.eventsRepository.save(event);

    // Keep the linked reminder (if any) in sync with a moved time or a
    // newly-set/changed lead time — this is what makes "перенеси встречу на
    // 17:00" also move its reminder instead of leaving a stale one behind.
    if (dto.startAt !== undefined || dto.reminderMinutes !== undefined) {
      const existingReminder = await this.remindersService.findByCalendarEvent(userId, saved.id);
      if (existingReminder && saved.reminderMinutes !== undefined) {
        const newRemindAt = new Date(saved.startAt.getTime() - saved.reminderMinutes * 60_000);
        await this.remindersService.update(userId, existingReminder.id, {
          remindAt: newRemindAt.toISOString(),
        });
      } else if (!existingReminder && saved.reminderMinutes !== undefined) {
        await this.remindersService.create(
          userId,
          {
            title: `Встреча: ${saved.title}`,
            remindAt: new Date(
              saved.startAt.getTime() - saved.reminderMinutes * 60_000,
            ).toISOString(),
            timezone: saved.timezone,
          },
          { calendarEventId: saved.id },
        );
      }
    }

    return saved;
  }

  async remove(userId: string, id: string): Promise<void> {
    const event = await this.findOneForUser(userId, id);
    // The reminders.calendar_event_id FK is ON DELETE CASCADE, so any
    // linked reminder is removed by the database automatically.
    await this.eventsRepository.remove(event);
  }
}
