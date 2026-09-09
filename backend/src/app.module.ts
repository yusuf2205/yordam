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
        // MVP only: lets TypeORM create/update tables from entities without
        // hand-written migrations. Turn this off and switch to real
        // migrations before there is production data to lose.
        synchronize: configService.get<string>('NODE_ENV', 'development') !== 'production',
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
