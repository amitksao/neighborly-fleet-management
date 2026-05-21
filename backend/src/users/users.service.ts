import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  async findOne(id: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { id } });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { email } });
  }

  async findByPhone(phone: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { phone } });
  }

  async updateTimezone(id: string, timezone: string): Promise<User> {
    await this.usersRepository.update(id, { timezone });
    return this.findOne(id);
  }

  async updateDeviceToken(id: string, deviceToken: string, platform?: string): Promise<void> {
    await this.usersRepository.update(id, { deviceToken, platform });
  }
}
