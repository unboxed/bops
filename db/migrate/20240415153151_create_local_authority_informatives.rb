# frozen_string_literal: true

class CreateLocalAuthorityInformatives < ActiveRecord::Migration[7.1]
  def change
    sql = <<~SQL.squish
      to_tsvector('simple',
        COALESCE(title, '') || ' ' ||
        COALESCE(text, '') || ' '
      )
    SQL

    create_table :local_authority_informatives do |t|
      t.references :local_authority
      t.string :title
      t.text :text
      t.virtual :search, type: :tsvector, as: sql, stored: true
      t.timestamps
    end
  end
end
