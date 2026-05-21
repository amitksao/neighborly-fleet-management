import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum UserRole {
  ADMIN = 'admin',
  RIDER = 'rider',
  DRIVER = 'driver',
  FLEET_MANAGER = 'fleet_manager',
}

export enum UserGender {
  MALE = 'male',
  FEMALE = 'female',
  OTHER = 'other',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true, nullable: true })
  phone: string;

  @Column({ nullable: true })
  profile_picture: string;

  @Column({ default: false })
  isVerified: boolean;

  @Column({ nullable: true })
  name: string;

  @Column({ nullable: true })
  password: string;

  @Column({ nullable: true })
  dob: Date;

  @Column({ type: 'enum', enum: UserGender, nullable: true })
  gender?: UserGender;

  @Column({ unique: true, nullable: true })
  email?: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ default: false })
  isProfileComplete: boolean;

  @Column({ type: 'enum', enum: UserRole, default: UserRole.RIDER })
  role: UserRole;

  @Column({ type: 'json', nullable: true })
  lastLocation: { latitude: number; longitude: number };

  @Column({ nullable: true })
  deviceToken: string;

  @Column({ nullable: true })
  platform: string;

  @Column({ type: 'decimal', precision: 3, scale: 2, nullable: true, default: 0 })
  averageRating: number;

  @Column({ type: 'int', default: 0 })
  totalReviews: number;

  @Column({ type: 'varchar', nullable: true, default: 'America/Chicago' })
  timezone: string;
}
