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
import { Task } from '../../tasks/entities/task.entity.js';

export enum ReminderStatus {
  PENDING = 'pending',
  SENT = 'sent',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
  FAILED = 'failed',
}

@Entity('reminders')
export class Reminder {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'user_id' })
  userId!: string;

  // Optional link to the task this reminder is about, if any (e.g. a task
  // with a due date the user asked to be reminded of). Nullable because a
  // reminder can also stand alone ("напомни мне позвонить" with no task).
  @ManyToOne(() => Task, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'task_id' })
  task?: Task;

  @Column({ name: 'task_id', nullable: true })
  taskId?: string;

  // Link to a calendar event, once calendar_events exists (see yordam.md
  // section 13/16, Phase 5). No FK constraint yet — the table doesn't exist
  // on this migration — just reserving the column so Phase 5 doesn't need a
  // reminders schema change, only an ALTER TABLE ADD CONSTRAINT.
  @Column({ name: 'calendar_event_id', nullable: true })
  calendarEventId?: string;

  @Column()
  title!: string;

  @Column({ name: 'remind_at', type: 'timestamptz' })
  remindAt!: Date;

  // IANA timezone name (e.g. "Asia/Tashkent"), for display purposes —
  // remindAt itself is already an absolute instant (timestamptz).
  @Column({ default: 'Asia/Tashkent' })
  timezone!: string;

  @Column({ type: 'varchar', default: ReminderStatus.PENDING })
  status!: ReminderStatus;

  // Set once a local/push notification has actually been scheduled for this
  // reminder (Phase 4) — lets the scheduler find and cancel it if the
  // reminder is edited or removed.
  @Column({ name: 'notification_id', nullable: true })
  notificationId?: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
