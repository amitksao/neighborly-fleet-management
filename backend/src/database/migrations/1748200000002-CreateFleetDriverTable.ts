import { MigrationInterface, QueryRunner, Table, TableForeignKey } from 'typeorm';

export class CreateFleetDriverTable1748200000002 implements MigrationInterface {
  name = 'CreateFleetDriverTable1748200000002';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE TYPE "fleet_driver_status_enum" AS ENUM('invited', 'bgc_pending', 'active', 'inactive', 'rejected')`);
    await queryRunner.query(`CREATE TYPE "fleet_invite_status_enum" AS ENUM('pending', 'accepted', 'expired')`);

    await queryRunner.createTable(
      new Table({
        name: 'fleet_drivers',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          {
            name: 'fleet_id',
            type: 'uuid',
            isNullable: false,
          },
          {
            name: 'driver_user_id',
            type: 'uuid',
            isNullable: true,
          },
          {
            name: 'status',
            type: 'enum',
            enum: ['invited', 'bgc_pending', 'active', 'inactive', 'rejected'],
            default: "'invited'",
            isNullable: false,
          },
          {
            name: 'invite_token',
            type: 'varchar',
            length: '512',
            isNullable: true,
            isUnique: true,
          },
          {
            name: 'invite_email',
            type: 'varchar',
            length: '255',
            isNullable: false,
          },
          {
            name: 'invite_expires_at',
            type: 'timestamp',
            isNullable: true,
          },
          {
            name: 'bgc_request_id',
            type: 'varchar',
            length: '255',
            isNullable: true,
          },
          {
            name: 'activated_at',
            type: 'timestamp',
            isNullable: true,
          },
          {
            name: 'deactivated_at',
            type: 'timestamp',
            isNullable: true,
          },
          {
            name: 'rejection_reason',
            type: 'text',
            isNullable: true,
          },
          {
            name: 'created_at',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
            isNullable: false,
          },
          {
            name: 'updated_at',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
            isNullable: false,
          },
        ],
      }),
      true,
    );

    await queryRunner.createTable(
      new Table({
        name: 'fleet_invites',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          {
            name: 'fleet_id',
            type: 'uuid',
            isNullable: false,
          },
          {
            name: 'invited_email',
            type: 'varchar',
            length: '255',
            isNullable: false,
          },
          {
            name: 'invite_token',
            type: 'varchar',
            length: '512',
            isUnique: true,
            isNullable: false,
          },
          {
            name: 'status',
            type: 'enum',
            enum: ['pending', 'accepted', 'expired'],
            default: "'pending'",
            isNullable: false,
          },
          {
            name: 'sent_at',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
            isNullable: false,
          },
          {
            name: 'accepted_at',
            type: 'timestamp',
            isNullable: true,
          },
          {
            name: 'expires_at',
            type: 'timestamp',
            isNullable: false,
          },
          {
            name: 'created_at',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
            isNullable: false,
          },
        ],
      }),
      true,
    );

    await queryRunner.createForeignKey(
      'fleet_drivers',
      new TableForeignKey({
        columnNames: ['fleet_id'],
        referencedColumnNames: ['id'],
        referencedTableName: 'fleets',
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      }),
    );

    await queryRunner.createForeignKey(
      'fleet_drivers',
      new TableForeignKey({
        columnNames: ['driver_user_id'],
        referencedColumnNames: ['id'],
        referencedTableName: 'users',
        onDelete: 'SET NULL',
        onUpdate: 'CASCADE',
      }),
    );

    await queryRunner.createForeignKey(
      'fleet_invites',
      new TableForeignKey({
        columnNames: ['fleet_id'],
        referencedColumnNames: ['id'],
        referencedTableName: 'fleets',
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE',
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    for (const tableName of ['fleet_invites', 'fleet_drivers']) {
      const table = await queryRunner.getTable(tableName);
      if (table) {
        for (const fk of table.foreignKeys) {
          await queryRunner.dropForeignKey(tableName, fk);
        }
      }
      await queryRunner.dropTable(tableName);
    }
    await queryRunner.query(`DROP TYPE IF EXISTS "fleet_invite_status_enum"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "fleet_driver_status_enum"`);
  }
}
