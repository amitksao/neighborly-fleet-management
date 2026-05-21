import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  ManyToMany,
  JoinTable,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum CommunityType {
  PERSONAL = 'personal',
  FLEET = 'fleet',
}

@Entity('communities')
export class Community {
  @PrimaryGeneratedColumn('uuid')
  community_id: string;

  @Column({ type: 'enum', enum: CommunityType, default: CommunityType.PERSONAL })
  type: CommunityType;

  @Column({ name: 'fleet_id', type: 'uuid', nullable: true })
  fleet_id: string;

  @Column({ name: 'is_public', default: true })
  is_public: boolean;

  @Column({ name: 'auto_approve_riders', default: false })
  auto_approve_riders: boolean;

  @Column({ length: 100 })
  name: string;

  @Column({ nullable: true })
  pfp: string;

  @Column({ length: 500, nullable: true })
  description: string;

  @ManyToOne(() => User, { nullable: true, eager: false })
  @JoinColumn({ name: 'driver_user_id' })
  driver: User;

  @ManyToMany(() => User, { eager: false })
  @JoinTable({
    name: 'community_riders',
    joinColumn: { name: 'community_id', referencedColumnName: 'community_id' },
    inverseJoinColumn: { name: 'user_id', referencedColumnName: 'id' },
  })
  riders: User[];

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
