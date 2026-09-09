import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { UsersModule } from './users/users.module.js';
import { AuthModule } from './auth/auth.module.js';
import { TasksModule } from './tasks/tasks.module.js';
import { AiModule } from './ai/ai.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('DB_HOST', 'localhost'),
        port: configService.get<number>('DB_PORT', 5432),
        username: configService.get<string>('DB_USER', 'yordam'),
        password: configService.get<string>('DB_PASSWORD', 'yordam'),
        database: configService.get<string>('DB_NAME', 'yordam'),
        autoLoadEntities: true,
        // Dev convenience: auto-create/update tables from entities. Off in
        // production, where the migrations below are the source of truth
        // instead (see src/migrations and package.json's typeorm scripts).
        synchronize: configService.get<string>('NODE_ENV', 'development') !== 'production',
        migrations: ['dist/migrations/*.js'],
        // Applies any pending migrations on boot in production, so a fresh
        // deployment ends up with the right schema without a manual step.
        migrationsRun: configService.get<string>('NODE_ENV', 'development') === 'production',
      }),
    }),
    UsersModule,
    AuthModule,
    TasksModule,
    AiModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
