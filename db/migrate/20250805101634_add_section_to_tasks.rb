# frozen_string_literal: true

class AddSectionToTasks < ActiveRecord::Migration[7.2]
  def change
    add_column :tasks, :section, :string
  end
end
