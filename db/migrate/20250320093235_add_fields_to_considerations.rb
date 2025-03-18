# frozen_string_literal: true

class AddFieldsToConsiderations < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      change_table :considerations, bulk: true do |t|
        t.string :proposal
        t.string :summary_tag
        t.boolean :draft, default: false, null: false
      end
    end
  end
end
