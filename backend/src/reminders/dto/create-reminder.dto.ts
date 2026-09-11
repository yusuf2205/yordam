import { IsDateString, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateReminderDto {
  @IsString()
  @MaxLength(255)
  title!: string;

  @IsDateString()
  remindAt!: string;

  @IsOptional()
  @IsString()
  timezone?: string;

  @IsOptional()
  @IsUUID()
  taskId?: string;
}
