import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { CurrentUser } from '../auth/decorators/current-user.decorator.js';
import type { JwtPayload } from '../auth/strategies/jwt.strategy.js';
import { CalendarService } from './calendar.service.js';
import { CreateCalendarEventDto } from './dto/create-calendar-event.dto.js';
import { UpdateCalendarEventDto } from './dto/update-calendar-event.dto.js';

@UseGuards(JwtAuthGuard)
@Controller('calendar-events')
export class CalendarController {
  constructor(private readonly calendarService: CalendarService) {}

  @Get()
  findAll(@CurrentUser() user: JwtPayload) {
    return this.calendarService.findAllForUser(user.sub);
  }

  @Get(':id')
  findOne(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.calendarService.findOneForUser(user.sub, id);
  }

  @Post()
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateCalendarEventDto) {
    return this.calendarService.create(user.sub, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateCalendarEventDto,
  ) {
    return this.calendarService.update(user.sub, id, dto);
  }

  @Delete(':id')
  remove(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.calendarService.remove(user.sub, id);
  }
}
