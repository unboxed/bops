# frozen_string_literal: true

class CreateApplicationTypeConfig < ActiveRecord::Migration[7.2]
  def change
    create_table :application_type_configs do |t|
      t.string :name, null: false
      t.integer :part
      t.string :section
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :assessment_details, array: true
      t.string :steps, default: ["validation", "consultation", "assessment", "review"], array: true
      t.string :consistency_checklist, array: true
      t.jsonb :document_tags, default: {}, null: false
      t.jsonb :features, default: {}
      t.string :status, default: "inactive", null: false
      t.string :code, null: false
      t.string :suffix, null: false
      t.integer :determination_period_days
      t.references :legislation, index: true, foreign_key: true
      t.boolean :configured, default: false, null: false
      t.string :category
      t.string :reporting_types, default: [], null: false, array: true
      t.string :decisions, default: [], null: false, array: true
      t.index [:code], name: "ix_application_type_configs_on_code", unique: true, where: "((status)::text <> 'retired'::text)"
      t.index [:suffix], name: "ix_application_type_configs_on_suffix", unique: true
    end
  end
end
