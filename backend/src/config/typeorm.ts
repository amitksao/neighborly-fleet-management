import { registerAs } from '@nestjs/config';
import { DataSource, DataSourceOptions } from 'typeorm';
import { env } from './env';

const config: DataSourceOptions = {
  type: 'postgres',
  url: process.env.DATABASE_URL,
  host: env.DB.HOST,
  port: parseInt(env.DB.PORT as string) || 5432,
  username: env.DB.USERNAME,
  password: env.DB.PASSWORD,
  database: env.DB.DATABASE,
  entities: [__dirname + '/../**/*.entity{.ts,.js}'],
  migrations: [__dirname + '/../database/migrations/*{.ts,.js}'],
  synchronize: false,
  ssl: process.env.SSL_MODE === 'true' ? { rejectUnauthorized: false } : false,
  extra: process.env.DATABASE_URL
    ? { ssl: { rejectUnauthorized: false } }
    : undefined,
};

export default registerAs('typeorm', () => config);
export const connectionSource = new DataSource(config);
