# frozen_string_literal: true

class DropLocalAuthorityCategoriesTable < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      drop_table :local_authority_categories do |t|
        t.references :local_authority, null: false, index: true, foreign_key: true
        t.string :description, null: false
        t.virtual :search, type: :tsvector, as: category_sql, stored: true

        t.timestamps

        t.index [:local_authority_id, :description], unique: true
        t.index [:local_authority_id, :search], using: :gin
      end
    end
  end
end
