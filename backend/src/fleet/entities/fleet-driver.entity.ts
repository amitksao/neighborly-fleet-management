import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { Fleet } from './fleet.entity';
import { User } from '../../../src/users/entities/user.entity';

export enum FleetDriverStatus {
  INVITED = 'invited',
  BGC_PENDING = 'bgc_pending',
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  REJECTED = 'rejected',
}

@Entity('fleet_drivers')
@Index(['fleet_id', 'driver_user_id'], { unique: true, where: 'driver_user_id IS NOT NULL' })
export class FleetDriver {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'fleet_id', type: 'uuid' })
  fleetId: string;

  @ManyToOne(() => Fleet, fleet => fleet.fleetDrivers, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'fleet_id' })
  fleet: Fleet;

  @Column({ name: 'driver_user_id', type: 'uuid', nullable: true })
  driverUserId: string;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'driver_user_id' })
  driver: User;

  @Column({
    type: 'enum',
    enum: FleetDriverStatus,
    default: FleetDriverStatus.INVITED,
  })
  status: FleetDriverStatus;

  @Column({ name: 'invite_token', length: 512, nullable: true, unique: true })
  inviteToken: string;

  @Column({ name: 'invite_email', length: 255 })
  inviteEmail: string;

  @Column({ name: 'invite_expires_at', type: 'timestamp', nullable: true })
  inviteExpiresAt: Date;

  @Column({ name: 'bgc_request_id', length: 255, nullable: true })
  bgcRequestId: string;

  @Column({ name: 'activated_at', type: 'timestamp', nullable: true })
  activatedAt: Date;

  @Column({ name: 'deactivated_at', type: 'timestamp', nullable: true })
  deactivatedAt: Date;

  @Column({ type: 'text', nullable: true })
  rejection_reason: string;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
