import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service.js';
import { RegisterDto } from './dto/register.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { ResetPasswordDto } from './dto/reset-password.dto.js';
import { hashPassword, verifyPassword } from './password.util.js';

export interface AuthResult {
  accessToken: string;
  user: {
    id: string;
    phone: string;
    name?: string;
    language: string;
  };
}

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto): Promise<AuthResult> {
    const existing = await this.usersService.findByPhone(dto.phone);
    if (existing) {
      throw new ConflictException('Phone number is already registered');
    }
    const passwordHash = await hashPassword(dto.password);
    const user = await this.usersService.create({
      phone: dto.phone,
      passwordHash,
      name: dto.name,
    });
    return this.buildResult(user.id, user.phone, user.name, user.language);
  }

  async login(dto: LoginDto): Promise<AuthResult> {
    const user = await this.usersService.findByPhone(dto.phone);
    if (!user) {
      throw new UnauthorizedException('Invalid phone or password');
    }
    const valid = await verifyPassword(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid phone or password');
    }
    return this.buildResult(user.id, user.phone, user.name, user.language);
  }

  async resetPassword(dto: ResetPasswordDto): Promise<void> {
    const user = await this.usersService.findByPhone(dto.phone);
    if (!user) {
      throw new NotFoundException('No account with this phone number');
    }
    const passwordHash = await hashPassword(dto.newPassword);
    await this.usersService.updatePasswordHash(user.id, passwordHash);
  }

  private buildResult(
    id: string,
    phone: string,
    name: string | undefined,
    language: string,
  ): AuthResult {
    const accessToken = this.jwtService.sign({ sub: id, phone });
    return { accessToken, user: { id, phone, name, language } };
  }
}
