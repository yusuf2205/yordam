import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Reminder } from './entities/reminder.entity.js';
import { CreateReminderDto } from './dto/create-reminder.dto.js';
import { UpdateReminderDto } from './dto/update-reminder.dto.js';

@Injectable()
export class RemindersService {
  constructor(
    @InjectRepository(Reminder)
    private readonly remindersRepository: Repository<Reminder>,
  ) {}

  findAllForUser(userId: string): Promise<Reminder[]> {
    return this.remindersRepository.find({
      where: { userId },
      order: { remindAt: 'ASC' },
    });
  }

  async findOneForUser(userId: string, id: string): Promise<Reminder> {
    const reminder = await this.remindersRepository.findOne({ where: { id, userId } });
    if (!reminder) {
      throw new NotFoundException(`Reminder ${id} not found`);
    }
    return reminder;
  }

  create(
    userId: string,
    dto: CreateReminderDto,
    options: { calendarEventId?: string } = {},
  ): Promise<Reminder> {
    const reminder = this.remindersRepository.create({
      title: dto.title,
      remindAt: new Date(dto.remindAt),
      timezone: dto.timezone,
      taskId: dto.taskId,
      calendarEventId: options.calendarEventId,
      userId,
    });
    return this.remindersRepository.save(reminder);
  }

  findByCalendarEvent(userId: string, calendarEventId: string): Promise<Reminder | null> {
    return this.remindersRepository.findOne({ where: { userId, calendarEventId } });
  }

  async update(userId: string, id: string, dto: UpdateReminderDto): Promise<Reminder> {
    const reminder = await this.findOneForUser(userId, id);
    // Assign fields individually rather than spreading the DTO — see the
    // identical fix (and the reasoning) in tasks.service.ts's update().
    if (dto.title !== undefined) reminder.title = dto.title;
    if (dto.remindAt !== undefined) reminder.remindAt = new Date(dto.remindAt);
    if (dto.timezone !== undefined) reminder.timezone = dto.timezone;
    if (dto.status !== undefined) reminder.status = dto.status;
    return this.remindersRepository.save(reminder);
  }

  async remove(userId: string, id: string): Promise<void> {
    const reminder = await this.findOneForUser(userId, id);
    await this.remindersRepository.remove(reminder);
  }
}
