# frozen_string_literal: true

class CreateLocalAuthorityPolicies < ActiveRecord::Migration[7.1]
  def change
    enable_extension :btree_gin

    area_sql = <<~SQL.squish
      to_tsvector('simple', description)
    SQL

    create_table :local_authority_policy_areas do |t|
      t.references :local_authority, null: false, index: true, foreign_key: true
      t.string :description, null: false
      t.virtual :search, type: :tsvector, as: area_sql, stored: true

      t.timestamps

      t.index [:local_authority_id, :description], unique: true
      t.index [:local_authority_id, :search], using: :gin
    end

    reference_sql = <<~SQL.squish
      to_tsvector('simple', code || ' ' || description)
    SQL

    create_table :local_authority_policy_references do |t|
      t.references :local_authority, null: false, index: true, foreign_key: true
      t.string :code, null: false
      t.string :description, null: false
      t.string :url
      t.virtual :search, type: :tsvector, as: reference_sql, stored: true

      t.timestamps

      t.index [:local_authority_id, :code], unique: true
      t.index [:local_authority_id, :description], unique: true
      t.index [:local_authority_id, :search], using: :gin
    end

    create_table :local_authority_policy_areas_references, id: false do |t|
      t.references :policy_area, index: true, foreign_key: {to_table: :local_authority_policy_areas}
      t.references :policy_reference, index: true, foreign_key: {to_table: :local_authority_policy_references}
      t.index [:policy_area_id, :policy_reference_id], unique: true
    end
  end
end
