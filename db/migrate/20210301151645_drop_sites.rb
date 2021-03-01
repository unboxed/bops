class DropSites < ActiveRecord::Migration[6.0]
  def up
    drop_table "sites"
  end
  def down
    raise ActiveRecord::IrreversibleMigration
  end
  remove_index :planning_applications, name: :index_planning_applications_on_site_id
end
