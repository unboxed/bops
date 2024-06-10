# frozen_string_literal: true

class CreateLocalAuthorityPolicyGuidance < ActiveRecord::Migration[7.1]
  def change
    guidance_sql = <<~SQL.squish
      to_tsvector('simple', description)
    SQL

    create_table :local_authority_policy_guidances, if_not_exists: true do |t|
      t.references :local_authority, null: false, index: true, foreign_key: true
      t.string :description, null: false
      t.string :url
      t.virtual :search, type: :tsvector, as: guidance_sql, stored: true

      t.timestamps

      t.index [:local_authority_id, :description], unique: true
      t.index [:local_authority_id, :search], using: :gin
    end
  end
end
