import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { StripeAccountType, StripeAccountStatus, StripeCapability } from '../../config/stripe';

@Entity('stripe_connect_accounts')
@Index(['stripeAccountId'], { unique: true })
@Index(['userId'], { unique: true })
export class StripeConnectAccount {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'stripe_account_id', type: 'varchar', length: 255, unique: true })
  stripeAccountId: string;

  @Column({
    name: 'account_type',
    type: 'enum',
    enum: StripeAccountType,
    default: StripeAccountType.EXPRESS,
  })
  accountType: StripeAccountType;

  @Column({
    name: 'status',
    type: 'enum',
    enum: StripeAccountStatus,
    default: StripeAccountStatus.PENDING,
  })
  status: StripeAccountStatus;

  @Column({
    name: 'capabilities',
    type: 'jsonb',
    default: [StripeCapability.CARD_PAYMENTS, StripeCapability.TRANSFERS],
  })
  capabilities: StripeCapability[];

  @Column({ name: 'business_name', type: 'varchar', length: 255, nullable: true })
  businessName: string;

  @Column({ name: 'country', type: 'varchar', length: 2, nullable: true })
  country: string;

  @Column({ name: 'currency', type: 'varchar', length: 3, nullable: true })
  currency: string;

  @Column({ name: 'email', type: 'varchar', length: 255, nullable: true })
  email: string;

  @Column({ name: 'payouts_enabled', type: 'boolean', default: false })
  payoutsEnabled: boolean;

  @Column({ name: 'charges_enabled', type: 'boolean', default: false })
  chargesEnabled: boolean;

  @Column({ name: 'details_submitted', type: 'boolean', default: false })
  detailsSubmitted: boolean;

  @Column({ name: 'onboarding_url', type: 'text', nullable: true })
  onboardingUrl: string;

  @Column({ name: 'onboarding_url_expires_at', type: 'timestamp', nullable: true })
  onboardingUrlExpiresAt: Date;

  @Column({ name: 'requirements', type: 'jsonb', nullable: true })
  requirements: Record<string, any>;

  @Column({ name: 'metadata', type: 'jsonb', nullable: true })
  metadata: Record<string, any>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
