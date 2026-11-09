# frozen_string_literal: true

class CreateEnforcementActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :enforcement_activities do |t|
      t.references :enforcement
      t.string :category
      t.datetime :activity_date
      t.string :title
      t.string :details
      t.timestamps
    end
  end
end
