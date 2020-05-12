class ChangeUserColumnNull < ActiveRecord::Migration[6.0]
  def change
    change_column_null(:planning_applications, :user_id, true )
  end
end
