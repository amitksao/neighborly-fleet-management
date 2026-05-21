import { MigrationInterface, QueryRunner, TableColumn, TableForeignKey } from 'typeorm';

export class AddFleetTribeTypeToCommunities1748200000003 implements MigrationInterface {
  name = 'AddFleetTribeTypeToCommunities1748200000003';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE TYPE "community_type_enum" AS ENUM('personal', 'fleet')`);

    await queryRunner.addColumn(
      'communities',
      new TableColumn({
        name: 'type',
        type: 'enum',
        enum: ['personal', 'fleet'],
        default: "'personal'",
        isNullable: false,
      }),
    );

    await queryRunner.addColumn(
      'communities',
      new TableColumn({
        name: 'fleet_id',
        type: 'uuid',
        isNullable: true,
      }),
    );

    await queryRunner.addColumn(
      'communities',
      new TableColumn({
        name: 'is_public',
        type: 'boolean',
        default: true,
        isNullable: false,
      }),
    );

    await queryRunner.addColumn(
      'communities',
      new TableColumn({
        name: 'auto_approve_riders',
        type: 'boolean',
        default: false,
        isNullable: false,
      }),
    );

    await queryRunner.createForeignKey(
      'communities',
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
    const table = await queryRunner.getTable('communities');
    if (table) {
      const fk = table.foreignKeys.find(fk => fk.columnNames.includes('fleet_id'));
      if (fk) await queryRunner.dropForeignKey('communities', fk);
    }

    await queryRunner.dropColumn('communities', 'auto_approve_riders');
    await queryRunner.dropColumn('communities', 'is_public');
    await queryRunner.dropColumn('communities', 'fleet_id');
    await queryRunner.dropColumn('communities', 'type');
    await queryRunner.query(`DROP TYPE IF EXISTS "community_type_enum"`);
  }
}
