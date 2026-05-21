import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddFleetManagerRoleToUsers1748200000005 implements MigrationInterface {
  name = 'AddFleetManagerRoleToUsers1748200000005';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Add 'fleet_manager' to the existing user_role enum
    await queryRunner.query(`ALTER TYPE "user_role_enum" ADD VALUE IF NOT EXISTS 'fleet_manager'`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // PostgreSQL does not support removing enum values directly.
    // To roll back: recreate the enum without 'fleet_manager' and update the column.
    await queryRunner.query(`
      CREATE TYPE "user_role_enum_new" AS ENUM('rider', 'driver', 'admin')
    `);
    await queryRunner.query(`
      ALTER TABLE "users"
        ALTER COLUMN "role" DROP DEFAULT
    `);
    await queryRunner.query(`
      ALTER TABLE "users"
        ALTER COLUMN "role" TYPE "user_role_enum_new"
        USING (role::text::"user_role_enum_new")
    `);
    await queryRunner.query(`DROP TYPE "user_role_enum"`);
    await queryRunner.query(`ALTER TYPE "user_role_enum_new" RENAME TO "user_role_enum"`);
  }
}
