import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum RideStatus {
  REQUESTED = 'REQUESTED',
  SCHEDULED = 'SCHEDULED',
  ACCEPTED = 'ACCEPTED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
  EXPIRED = 'EXPIRED',
}

export enum PaymentStatus {
  PENDING = 'PENDING',
  PAID = 'PAID',
  FAILED = 'FAILED',
}

@Entity('rides')
export class Ride {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'rider_id' })
  rider: User;

  @Column({ name: 'rider_id', type: 'uuid', nullable: true })
  riderId: string;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'driver_id' })
  driver: User;

  @Column({ name: 'driver_id', type: 'uuid', nullable: true })
  driverId: string;

  @Column('decimal', { precision: 10, scale: 6 })
  pickup_latitude: number;

  @Column('decimal', { precision: 10, scale: 6 })
  pickup_longitude: number;

  @Column({ nullable: true, type: 'text' })
  pickup_address: string;

  @Column('decimal', { precision: 10, scale: 6 })
  dropoff_latitude: number;

  @Column('decimal', { precision: 10, scale: 6 })
  dropoff_longitude: number;

  @Column({ nullable: true, type: 'text' })
  dropoff_address: string;

  @Column({ nullable: true, type: 'decimal', precision: 10, scale: 2 })
  estimated_distance: number;

  @Column({ nullable: true, type: 'text' })
  estimated_duration: string;

  @Column({ nullable: true, type: 'text' })
  polyline: string;

  @Column({ type: 'timestamp' })
  scheduled_at: Date;

  @Column({ type: 'timestamp', nullable: true })
  started_at: Date;

  @Column({ type: 'timestamp', nullable: true })
  completed_at: Date;

  @Column('decimal', { precision: 10, scale: 2 })
  fare: number;

  @Column({ type: 'enum', enum: RideStatus, default: RideStatus.SCHEDULED })
  status: RideStatus;

  @Column({ nullable: true })
  cancellation_reason: string;

  @Column({ nullable: true, name: 'payment_intent_id' })
  paymentIntentId: string;

  @Column({ type: 'enum', enum: PaymentStatus, default: PaymentStatus.PENDING })
  paymentStatus: PaymentStatus;

  @Column({ name: 'fleet_id', type: 'uuid', nullable: true })
  fleet_id: string;

  @Column({ name: 'assignment_attempts', type: 'int', default: 0 })
  assignment_attempts: number;

  @Column({ name: 'fleet_payout_transfer_id', nullable: true })
  fleet_payout_transfer_id: string;

  @Column({ name: 'platform_fee_amount', type: 'decimal', precision: 10, scale: 2, nullable: true })
  platform_fee_amount: number;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
