# frozen_string_literal: true

class CreateContacts < ActiveRecord::Migration[7.0]
  def change
    sql = <<~SQL.squish
      to_tsvector('simple',
        COALESCE(name, '') || ' ' ||
        COALESCE(role, '') || ' ' ||
        COALESCE(organisation, '')
      )
    SQL

    create_table :contacts do |t|
      t.belongs_to :local_authority, index: true, foreign_key: true
      t.string :origin, null: false
      t.string :category, null: false
      t.string :name, null: false
      t.string :role
      t.string :organisation
      t.string :address_1
      t.string :address_2
      t.string :town
      t.string :county
      t.string :postcode
      t.string :email_address
      t.string :phone_number
      t.virtual :search, type: :tsvector, as: sql, stored: true
      t.timestamps
    end

    add_index :contacts, %i[local_authority_id category]
    add_index :contacts, :name
    add_index :contacts, :search, using: :gin
  end
end
