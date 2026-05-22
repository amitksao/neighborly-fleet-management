import {
  Injectable,
  ConflictException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { User, UserRole } from '../users/entities/user.entity';
import { Fleet } from '../fleet/entities/fleet.entity';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Fleet)
    private readonly fleetRepository: Repository<Fleet>,
    private readonly jwtService: JwtService,
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
