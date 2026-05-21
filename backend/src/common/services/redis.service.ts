import { Injectable, OnModuleDestroy, OnModuleInit, Logger } from '@nestjs/common';
import { createClient, RedisClientType } from 'redis';
import { env } from '../../config/env';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client: RedisClientType;
  private readonly ttl: number = 300;

  constructor() {
    this.client = createClient({
      url: env.REDIS.URL,
      socket: {
        reconnectStrategy: (retries) => {
          if (retries > 20) {
            this.logger.error('Redis connection lost. Max retries reached.');
            return new Error('Max retries reached');
          }
          return Math.min(retries * 100, 3000);
        },
      },
    }) as RedisClientType;
    this.client.on('error', (err) => this.logger.error('Redis Client Error', err));
    this.client.on('connect', () => this.logger.log('Redis Client Connected'));
  }

  isConnected(): boolean {
    return this.client.isOpen;
  }

  async onModuleInit() {
    try {
      await this.client.connect();
    } catch (error) {
      this.logger.error('Redis connection failed:', error);
      throw error;
    }
  }

  async onModuleDestroy() {
    try {
      await this.client.quit();
    } catch (error) {
      this.logger.error('Redis disconnect failed:', error);
    }
  }

  async set(key: string, value: string, ttl?: number): Promise<void> {
    await this.client.set(key, value, { EX: ttl || this.ttl });
  }

  async get(key: string): Promise<string | null> {
    return await this.client.get(key);
  }

  async del(key: string): Promise<void> {
    await this.client.del(key);
  }

  async incr(key: string): Promise<number> {
    return await this.client.incr(key);
  }

  async expire(key: string, seconds: number): Promise<void> {
    await this.client.expire(key, seconds);
  }

  async getTTL(key: string): Promise<number> {
    return await this.client.ttl(key);
  }

  async keyExists(key: string): Promise<boolean> {
    const result = await this.client.exists(key);
    return result === 1;
  }
}
