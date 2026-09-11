import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddCalendarEvents1789163542564 implements MigrationInterface {
  name = 'AddCalendarEvents1789163542564';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "calendar_events" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "user_id" uuid NOT NULL,
        "title" character varying NOT NULL,
        "description" text,
        "location" character varying,
        "start_at" TIMESTAMP WITH TIME ZONE NOT NULL,
        "end_at" TIMESTAMP WITH TIME ZONE,
        "timezone" character varying NOT NULL DEFAULT 'Asia/Tashkent',
        "reminder_minutes" integer,
        "status" character varying NOT NULL DEFAULT 'confirmed',
        "external_id" character varying,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_calendar_events" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      ALTER TABLE "calendar_events" ADD CONSTRAINT "FK_calendar_events_user_id"
        FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
    `);

    // reminders.calendar_event_id was reserved without a FK when reminders
    // was created (calendar_events didn't exist yet) — add it now.
    await queryRunner.query(`
      ALTER TABLE "reminders" ADD CONSTRAINT "FK_reminders_calendar_event_id"
        FOREIGN KEY ("calendar_event_id") REFERENCES "calendar_events"("id") ON DELETE CASCADE
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "reminders" DROP CONSTRAINT "FK_reminders_calendar_event_id"`);
    await queryRunner.query(`ALTER TABLE "calendar_events" DROP CONSTRAINT "FK_calendar_events_user_id"`);
    await queryRunner.query(`DROP TABLE "calendar_events"`);
  }
}
