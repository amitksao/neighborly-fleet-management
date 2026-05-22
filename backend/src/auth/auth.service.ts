import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { User, UserRole } from '../users/entities/user.entity';
import { Fleet } from '../fleet/entities/fleet.entity';
import { RegisterDto } from './dto/register.dto';
import { EmailService } from '../common/services/email.service';
import { RedisService } from '../common/services/redis.service';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly RESET_EXPIRY = '15m';

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Fleet)
    private readonly fleetRepository: Repository<Fleet>,
    private readonly jwtService: JwtService,
    private readonly emailService: EmailService,
    private readonly redisService: RedisService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.userRepository.findOne({
      where: { email: dto.email },
    });
    if (existing) throw new ConflictException('Email already in use');

    const hashed = await bcrypt.hash(dto.password, 10);
    const user = this.userRepository.create({
      name: dto.name,
      email: dto.email,
      password: hashed,
      role: UserRole.FLEET_MANAGER,
    });
    const saved = await this.userRepository.save(user);
    return this.buildResponse(saved);
  }

  async login(email: string, password: string) {
    const user = await this.userRepository.findOne({ where: { email } });
    if (!user || !user.password) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const match = await bcrypt.compare(password, user.password);
    if (!match) throw new UnauthorizedException('Invalid credentials');

    return this.buildResponse(user);
  }

  async forgotPassword(email: string): Promise<void> {
    const user = await this.userRepository.findOne({ where: { email } });
    // Always return success to avoid email enumeration
    if (!user) return;

    const token = this.jwtService.sign(
      { id: user.id, type: 'password_reset' },
      { expiresIn: this.RESET_EXPIRY },
    );

    const frontendUrl = process.env.APP_BASE_URL ?? 'http://localhost';
    const resetLink = `${frontendUrl}?reset_token=${token}`;

    await this.emailService.sendEmail(
      email,
      'Reset your Neighborly Fleet password',
      `<h2>Password Reset</h2>
       <p>Click the link below to reset your password. It expires in 15 minutes.</p>
       <p><a href="${resetLink}">Reset Password</a></p>
       <p>If you did not request this, ignore this email.</p>`,
    );

    this.logger.log(`Password reset email sent to ${email}`);
  }

  async resetPassword(token: string, newPassword: string): Promise<void> {
    let payload: { id: string; type: string; exp: number };
    try {
      payload = this.jwtService.verify(token) as { id: string; type: string; exp: number };
    } catch {
      throw new BadRequestException('Reset link is invalid or has expired');
    }

    if (payload.type !== 'password_reset') {
      throw new BadRequestException('Invalid reset token');
    }

    const blacklistKey = `used_reset_token:${token}`;
    if (await this.redisService.keyExists(blacklistKey)) {
      throw new BadRequestException('Reset link has already been used');
    }

    const user = await this.userRepository.findOne({ where: { id: payload.id } });
    if (!user) throw new BadRequestException('User not found');

    user.password = await bcrypt.hash(newPassword, 10);
    await this.userRepository.save(user);

    // Blacklist the token for its remaining lifetime so it cannot be reused
    const remainingTtl = payload.exp - Math.floor(Date.now() / 1000);
    if (remainingTtl > 0) {
      await this.redisService.set(blacklistKey, '1', remainingTtl);
    }

    this.logger.log(`Password reset for user ${user.id}`);
  }

  private async buildResponse(user: User) {
    const fleet = await this.fleetRepository.findOne({
      where: { managerUserId: user.id },
    });

    const token = this.jwtService.sign({ id: user.id, role: user.role });

    return {
      access_token: token,
      user: {
        id: user.id,
        email: user.email,
        firstName: user.name,
        fleetManagerOf: fleet?.id ?? null,
      },
    };
  }
}
