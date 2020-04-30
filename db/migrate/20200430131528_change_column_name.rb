class ChangeColumnName < ActiveRecord::Migration[6.0]
  def change
    rename_column :planning_applications, :code, :reference
  end
end
