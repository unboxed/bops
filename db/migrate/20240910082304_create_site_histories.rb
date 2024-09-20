# frozen_string_literal: true

class CreateSiteHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :site_histories do |t|
      t.date :date
      t.string :application_number
      t.string :description
      t.string :decision
      t.references :planning_application, null: false, foreign_key: true

      t.timestamps
    end
  end
end
