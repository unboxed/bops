# frozen_string_literal: true

class AddStatusHiddenToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :status_hidden, :boolean, default: false
    Task.reset_column_information
    Task.in_batches.update_all(status_hidden: false)

    safety_assured do
      change_column_null :tasks, :status_hidden, false
    end
  end
end
