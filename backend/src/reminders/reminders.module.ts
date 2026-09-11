import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Reminder } from './entities/reminder.entity.js';
import { RemindersService } from './reminders.service.js';
import { RemindersController } from './reminders.controller.js';
import { AuthModule } from '../auth/auth.module.js';

@Module({
  // AuthModule for PassportModule — RemindersController guards routes with
  // JwtAuthGuard (see auth/auth.module.ts for why this is needed).
  imports: [TypeOrmModule.forFeature([Reminder]), AuthModule],
  providers: [RemindersService],
  controllers: [RemindersController],
  exports: [RemindersService],
})
export class RemindersModule {}
