# frozen_string_literal: true

class CreateLocalAuthorityConditions < ActiveRecord::Migration[8.0]
  def change
    sql = <<~SQL.squish
      to_tsvector('simple',
        COALESCE(title, '') || ' ' ||
        COALESCE(text, '') || ' ' ||
        COALESCE(reason, '') || ' '
      )
    SQL

    create_table :local_authority_conditions do |t|
      t.references :local_authority
      t.string :title
      t.text :text
      t.text :reason
      t.boolean :standard, null: false, default: false
      t.virtual :search, type: :tsvector, as: sql, stored: true
      t.timestamps
    end
  end
end
