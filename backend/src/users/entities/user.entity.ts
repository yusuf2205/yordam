import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ unique: true })
  phone!: string;

  @Column({ nullable: true })
  name?: string;

  @Column({ nullable: true, unique: true })
  email?: string;

  // Password hash for the MVP auth flow (phone + password).
  // Section 14 of the product plan calls for phone OTP login; that requires
  // an SMS provider integration and is left as a follow-up. This column lets
  // us ship working auth now without blocking on that integration.
  @Column({ name: 'password_hash' })
  passwordHash!: string;

  @Column({ default: 'ru' })
  language!: string;

  @Column({ nullable: true })
  timezone?: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;
}
