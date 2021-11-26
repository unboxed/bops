class AddWardToPlanningApplication < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :ward, :string
  end
end
