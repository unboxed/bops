class RemoveDefaultApplicationType < ActiveRecord::Migration[6.0]
  def change
    change_column_default(:planning_applications, :application_type, nil)
  end
end
