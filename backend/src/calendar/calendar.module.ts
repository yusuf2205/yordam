import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CalendarEvent } from './entities/calendar-event.entity.js';
import { CalendarService } from './calendar.service.js';
import { CalendarController } from './calendar.controller.js';
import { RemindersModule } from '../reminders/reminders.module.js';
import { AuthModule } from '../auth/auth.module.js';

@Module({
  // AuthModule for PassportModule — CalendarController guards routes with
  // JwtAuthGuard (see auth/auth.module.ts for why this is needed).
  imports: [TypeOrmModule.forFeature([CalendarEvent]), RemindersModule, AuthModule],
  providers: [CalendarService],
  controllers: [CalendarController],
  exports: [CalendarService],
})
export class CalendarModule {}
