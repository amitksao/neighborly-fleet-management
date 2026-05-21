import { MigrationInterface, QueryRunner, Table, TableForeignKey } from 'typeorm';

export class CreateFleetTable1748200000001 implements MigrationInterface {
  name = 'CreateFleetTable1748200000001';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE TYPE "fleet_status_enum" AS ENUM('pending_approval', 'approved', 'rejected', 'suspended')`);

    await queryRunner.createTable(
      new Table({
        name: 'fleets',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          {
            name: 'company_name',
            type: 'varchar',
            length: '200',
            isNullable: false,
          },
          {
            name: 'company_email',
            type: 'varchar',
            length: '255',
            isUnique: true,
            isNullable: false,
          },
          {
            name: 'company_phone',
            type: 'varchar',
            length: '20',
            isNullable: true,
          },
          {
            name: 'company_address',
            type: 'text',
            isNullable: true,
          },
          {
            name: 'logo_url',
            type: 'varchar',
            length: '500',
            isNullable: true,
          },
          {
            name: 'description',
            type: 'text',
            isNullable: true,
          },
          {
            name: 'status',
            type: 'enum',
            enum: ['pending_approval', 'approved', 'rejected', 'suspended'],
            default: "'pending_approval'",
            isNullable: false,
          },
          {
            name: 'stripe_account_id',
            type: 'varchar',
            length: '255',
            isNullable: true,
          },
          {
            name: 'platform_fee_pct',
            type: 'decimal',
            precision: 5,
            scale: 2,
            default: 10,
            isNullable: false,
          },
          {
            name: 'manager_user_id',
            type: 'uuid',
            isNullable: false,
          },
          {
            name: 'tribe_id',
            type: 'uuid',
            isNullable: true,
          },
          {
            name: 'rejection_reason',
            type: 'text',
            isNullable: true,
          },
          {
            name: 'approved_at',
            type: 'timestamp',
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

    await queryRunner.createForeignKey(
      'fleets',
      new TableForeignKey({
        columnNames: ['manager_user_id'],
        referencedColumnNames: ['id'],
        referencedTableName: 'users',
        onDelete: 'RESTRICT',
        onUpdate: 'CASCADE',
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    const table = await queryRunner.getTable('fleets');
    if (table) {
      for (const fk of table.foreignKeys) {
        await queryRunner.dropForeignKey('fleets', fk);
      }
    }
    await queryRunner.dropTable('fleets');
    await queryRunner.query(`DROP TYPE IF EXISTS "fleet_status_enum"`);
  }
}
