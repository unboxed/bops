class AddTypeToAudit < ActiveRecord::Migration[6.0]
  def change
    add_column :audits, :activity_type, :jsonb, default: [], null: false
    rename_column :audits, :activity, :activity_information
  end
end
