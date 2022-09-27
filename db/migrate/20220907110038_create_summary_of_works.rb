# frozen_string_literal: true

class CreateSummaryOfWorks < ActiveRecord::Migration[6.1]
  def change
    create_table :summary_of_works do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :entry
      t.string :status, null: false

      t.timestamps
    end
  end
end
