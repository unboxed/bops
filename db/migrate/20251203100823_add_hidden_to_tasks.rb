# frozen_string_literal: true

class AddHiddenToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :hidden, :boolean, default: false
    Task.reset_column_information
    Task.in_batches.update_all(hidden: false)

    safety_assured do
      change_column_null :tasks, :hidden, false
    end
  end
end
