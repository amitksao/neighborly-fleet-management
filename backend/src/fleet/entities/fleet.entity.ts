import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  OneToOne,
  JoinColumn,
  Index,
} from 'typeorm';
// These imports reference the existing neighborly_backend source tree
// In integration, use relative paths adjusted to the monorepo layout
import { User } from '../../users/entities/user.entity';
import { Community } from '../../communities/entities/community.entity';
import { FleetDriver } from './fleet-driver.entity';

export enum FleetStatus {
  PENDING_APPROVAL = 'pending_approval',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  SUSPENDED = 'suspended',
}

@Entity('fleets')
@Index(['company_email'], { unique: true })
export class Fleet {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 200 })
  company_name: string;

  @Column({ length: 255, unique: true })
  company_email: string;

  @Column({ length: 20, nullable: true })
  company_phone: string;

  @Column({ type: 'text', nullable: true })
  company_address: string;

  @Column({ length: 500, nullable: true })
  logo_url: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({
    type: 'enum',
    enum: FleetStatus,
    default: FleetStatus.PENDING_APPROVAL,
  })
  status: FleetStatus;

  @Column({ length: 255, nullable: true })
  stripe_account_id: string;

  @Column({ type: 'decimal', precision: 5, scale: 2, default: 10 })
  platform_fee_pct: number;

  @Column({ name: 'manager_user_id', type: 'uuid' })
  managerUserId: string;

  @ManyToOne(() => User, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'manager_user_id' })
  manager: User;

  @Column({ name: 'tribe_id', type: 'uuid', nullable: true })
  tribeId: string;

  @OneToOne(() => Community)
  @JoinColumn({ name: 'tribe_id' })
  tribe: Community;

  @OneToMany(() => FleetDriver, fd => fd.fleet)
  fleetDrivers: FleetDriver[];

  @Column({ type: 'text', nullable: true })
  rejection_reason: string;

  @Column({ type: 'timestamp', nullable: true })
  approved_at: Date;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
