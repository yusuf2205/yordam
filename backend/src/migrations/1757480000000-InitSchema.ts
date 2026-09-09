import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitSchema1757480000000 implements MigrationInterface {
  name = 'InitSchema1757480000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp"`);

    await queryRunner.query(`
      CREATE TABLE "users" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "phone" character varying NOT NULL,
        "name" character varying,
        "email" character varying,
        "password_hash" character varying NOT NULL,
        "language" character varying NOT NULL DEFAULT 'ru',
        "timezone" character varying,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "UQ_users_phone" UNIQUE ("phone"),
        CONSTRAINT "UQ_users_email" UNIQUE ("email"),
        CONSTRAINT "PK_users" PRIMARY KEY ("id")
      )
    `);

    await queryRunner.query(`
      CREATE TABLE "tasks" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "user_id" uuid NOT NULL,
        "title" character varying NOT NULL,
        "description" text,
        "status" character varying NOT NULL DEFAULT 'pending',
        "priority" character varying NOT NULL DEFAULT 'medium',
        "due_date" TIMESTAMP WITH TIME ZONE,
        "created_by_ai" boolean NOT NULL DEFAULT false,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_tasks" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      ALTER TABLE "tasks" ADD CONSTRAINT "FK_tasks_user_id"
        FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
    `);

    await queryRunner.query(`
      CREATE TABLE "ai_conversations" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "user_id" uuid NOT NULL,
        "title" character varying,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_ai_conversations" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      ALTER TABLE "ai_conversations" ADD CONSTRAINT "FK_ai_conversations_user_id"
        FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
    `);

    await queryRunner.query(`
      CREATE TABLE "ai_messages" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "conversation_id" uuid NOT NULL,
        "role" character varying NOT NULL,
        "content" text NOT NULL,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_ai_messages" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      ALTER TABLE "ai_messages" ADD CONSTRAINT "FK_ai_messages_conversation_id"
        FOREIGN KEY ("conversation_id") REFERENCES "ai_conversations"("id") ON DELETE CASCADE
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "ai_messages" DROP CONSTRAINT "FK_ai_messages_conversation_id"`);
    await queryRunner.query(`DROP TABLE "ai_messages"`);
    await queryRunner.query(`ALTER TABLE "ai_conversations" DROP CONSTRAINT "FK_ai_conversations_user_id"`);
    await queryRunner.query(`DROP TABLE "ai_conversations"`);
    await queryRunner.query(`ALTER TABLE "tasks" DROP CONSTRAINT "FK_tasks_user_id"`);
    await queryRunner.query(`DROP TABLE "tasks"`);
    await queryRunner.query(`DROP TABLE "users"`);
  }
}
