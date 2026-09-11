import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity.js';

export enum CalendarEventStatus {
  CONFIRMED = 'confirmed',
  CANCELLED = 'cancelled',
}

@Entity('calendar_events')
export class CalendarEvent {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'user_id' })
  userId!: string;

  @Column()
  title!: string;

  @Column({ type: 'text', nullable: true })
  description?: string;

  @Column({ nullable: true })
  location?: string;

  @Column({ name: 'start_at', type: 'timestamptz' })
  startAt!: Date;

  @Column({ name: 'end_at', type: 'timestamptz', nullable: true })
  endAt?: Date;

  @Column({ default: 'Asia/Tashkent' })
  timezone!: string;

  // How many minutes before startAt to remind the user, if at all — used to
  // create a linked Reminder row (see reminders.calendar_event_id) at the
  // same time as the event itself.
  @Column({ name: 'reminder_minutes', type: 'int', nullable: true })
  reminderMinutes?: number;

  @Column({ type: 'varchar', default: CalendarEventStatus.CONFIRMED })
  status!: CalendarEventStatus;

  // Reserved for linking to a system/external calendar entry (e.g. the
  // Android Calendar Provider event id) once that sync exists — unused for
  // now, nothing populates it yet.
  @Column({ name: 'external_id', nullable: true })
  externalId?: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
