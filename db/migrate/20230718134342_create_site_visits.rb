# frozen_string_literal: true

class CreateSiteVisits < ActiveRecord::Migration[7.0]
  def change
    create_table :site_visits do |t|
      t.references :consultation, foreign_key: true
      t.references :created_by, null: false, foreign_key: {to_table: :users}
      t.string :status, default: "not_started", null: false
      t.text :comment, null: false
      t.boolean :decision, null: false
      t.datetime :visited_at

      t.timestamps
    end

    add_reference :documents, :site_visit, null: true, foreign_key: true
  end
end
