import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { Fleet } from './fleet.entity';

export enum FleetInviteStatus {
  PENDING = 'pending',
  ACCEPTED = 'accepted',
  EXPIRED = 'expired',
}

@Entity('fleet_invites')
@Index(['inviteToken'], { unique: true })
export class FleetInvite {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'fleet_id', type: 'uuid' })
  fleetId: string;

  @ManyToOne(() => Fleet, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'fleet_id' })
  fleet: Fleet;

  @Column({ name: 'invited_email', length: 255 })
  invitedEmail: string;

  @Column({ name: 'invite_token', length: 512, unique: true })
  inviteToken: string;

  @Column({
    type: 'enum',
    enum: FleetInviteStatus,
    default: FleetInviteStatus.PENDING,
  })
  status: FleetInviteStatus;

  @Column({ name: 'expires_at', type: 'timestamp' })
  expiresAt: Date;

  @Column({ name: 'accepted_at', type: 'timestamp', nullable: true })
  acceptedAt: Date;

  @CreateDateColumn({ name: 'sent_at' })
  sentAt: Date;

  @CreateDateColumn({ name: 'created_at' })
  created_at: Date;
}
