import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Task } from './entities/task.entity.js';
import { CreateTaskDto } from './dto/create-task.dto.js';
import { UpdateTaskDto } from './dto/update-task.dto.js';

@Injectable()
export class TasksService {
  constructor(
    @InjectRepository(Task)
    private readonly tasksRepository: Repository<Task>,
  ) {}

  findAllForUser(userId: string): Promise<Task[]> {
    return this.tasksRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async findOneForUser(userId: string, id: string): Promise<Task> {
    const task = await this.tasksRepository.findOne({ where: { id, userId } });
    if (!task) {
      throw new NotFoundException(`Task ${id} not found`);
    }
    return task;
  }

  create(
    userId: string,
    dto: CreateTaskDto,
    options: { createdByAi?: boolean } = {},
  ): Promise<Task> {
    const task = this.tasksRepository.create({
      ...dto,
      dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
      userId,
      createdByAi: options.createdByAi ?? false,
    });
    return this.tasksRepository.save(task);
  }

  async update(userId: string, id: string, dto: UpdateTaskDto): Promise<Task> {
    const task = await this.findOneForUser(userId, id);
    // Assign fields individually (not via `{ ...dto }` spread) because a
    // class-validator DTO instance carries every declared property as an
    // own key, `undefined` for the ones absent from the request body —
    // spreading it into Object.assign would overwrite untouched columns
    // (e.g. title, priority) with undefined instead of leaving them as-is.
    if (dto.title !== undefined) task.title = dto.title;
    if (dto.description !== undefined) task.description = dto.description;
    if (dto.status !== undefined) task.status = dto.status;
    if (dto.priority !== undefined) task.priority = dto.priority;
    if (dto.dueDate !== undefined) task.dueDate = new Date(dto.dueDate);
    return this.tasksRepository.save(task);
  }

  async remove(userId: string, id: string): Promise<void> {
    const task = await this.findOneForUser(userId, id);
    await this.tasksRepository.remove(task);
  }
}
