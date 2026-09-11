import { IsDateString, IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { ReminderStatus } from '../entities/reminder.entity.js';

export class UpdateReminderDto {
  @IsOptional()
  @IsString()
  @MaxLength(255)
  title?: string;

  @IsOptional()
  @IsDateString()
  remindAt?: string;

  @IsOptional()
  @IsString()
  timezone?: string;

  @IsOptional()
  @IsEnum(ReminderStatus)
  status?: ReminderStatus;
}
