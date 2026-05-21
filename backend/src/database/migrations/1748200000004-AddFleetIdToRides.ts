import { MigrationInterface, QueryRunner, TableColumn, TableForeignKey } from 'typeorm';

export class AddFleetIdToRides1748200000004 implements MigrationInterface {
  name = 'AddFleetIdToRides1748200000004';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.addColumn(
      'rides',
      new TableColumn({
        name: 'fleet_id',
        type: 'uuid',
        isNullable: true,
      }),
    );

    await queryRunner.addColumn(
      'rides',
      new TableColumn({
        name: 'assignment_attempts',
        type: 'integer',
        default: 0,
        isNullable: false,
      }),
    );

    await queryRunner.addColumn(
      'rides',
      new TableColumn({
        name: 'fleet_payout_transfer_id',
        type: 'varchar',
        length: '255',
        isNullable: true,
      }),
    );

    await queryRunner.addColumn(
      'rides',
      new TableColumn({
        name: 'platform_fee_amount',
        type: 'decimal',
        precision: 10,
        scale: 2,
        isNullable: true,
      }),
    );

    await queryRunner.createForeignKey(
      'rides',
      new TableForeignKey({
        columnNames: ['fleet_id'],
        referencedColumnNames: ['id'],
        referencedTableName: 'fleets',
        onDelete: 'SET NULL',
        onUpdate: 'CASCADE',
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    const table = await queryRunner.getTable('rides');
    if (table) {
      const fk = table.foreignKeys.find(fk => fk.columnNames.includes('fleet_id'));
      if (fk) await queryRunner.dropForeignKey('rides', fk);
    }

    await queryRunner.dropColumn('rides', 'platform_fee_amount');
    await queryRunner.dropColumn('rides', 'fleet_payout_transfer_id');
    await queryRunner.dropColumn('rides', 'assignment_attempts');
    await queryRunner.dropColumn('rides', 'fleet_id');
  }
}
