# frozen_string_literal: true

class AddRegulation3AndRegulation4ToPlanningApplication < ActiveRecord::Migration[7.1]
  def change
    safety_assured {
      change_table :planning_applications, bulk: true do |t|
        t.boolean :regulation_3, default: false, null: false
        t.boolean :regulation_4, default: false, null: false
      end
    }
  end
end
