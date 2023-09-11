# frozen_string_literal: true

class CreatePlanxPlanningData < ActiveRecord::Migration[7.0]
  def up
    create_table :planx_planning_data do |t|
      t.jsonb :entry, null: false
      t.references :planning_application, index: true, foreign_key: true

      t.timestamps
    end

    execute <<~SQL.squish
      INSERT INTO planx_planning_data (entry, planning_application_id, created_at, updated_at)
      SELECT planx_data, id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM planning_applications
      WHERE planx_data IS NOT NULL;
    SQL
  end

  def down
    drop_table :planx_planning_data if table_exists?(:planx_planning_data)
  end
end
