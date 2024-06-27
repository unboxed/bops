# frozen_string_literal: true

class CreateConsiderationSet < ActiveRecord::Migration[7.1]
  def change
    create_table :consideration_sets do |t|
      t.references :planning_application, foreign_key: true
      t.timestamps
    end
  end
end
