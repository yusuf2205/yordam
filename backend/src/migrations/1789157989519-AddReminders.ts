import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddReminders1789157989519 implements MigrationInterface {
  name = 'AddReminders1789157989519';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "reminders" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "user_id" uuid NOT NULL,
        "task_id" uuid,
        "calendar_event_id" uuid,
        "title" character varying NOT NULL,
        "remind_at" TIMESTAMP WITH TIME ZONE NOT NULL,
        "timezone" character varying NOT NULL DEFAULT 'Asia/Tashkent',
        "status" character varying NOT NULL DEFAULT 'pending',
        "notification_id" character varying,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_reminders" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      ALTER TABLE "reminders" ADD CONSTRAINT "FK_reminders_user_id"
        FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
    `);
    await queryRunner.query(`
      ALTER TABLE "reminders" ADD CONSTRAINT "FK_reminders_task_id"
        FOREIGN KEY ("task_id") REFERENCES "tasks"("id") ON DELETE CASCADE
    `);
    // No FK for calendar_event_id yet — calendar_events doesn't exist until
    // Phase 5. Add it with a follow-up migration once that table lands.
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "reminders" DROP CONSTRAINT "FK_reminders_task_id"`);
    await queryRunner.query(`ALTER TABLE "reminders" DROP CONSTRAINT "FK_reminders_user_id"`);
    await queryRunner.query(`DROP TABLE "reminders"`);
  }
}
