class ChangeColumnTypeConstraints < ActiveRecord::Migration[6.1]
  def change
    remove_column :planning_applications, :constraints, :jsonb
    add_column :planning_applications, :constraints, :text, array:true, default: [], null:false
  end
end
