# frozen_string_literal: true

class CreateApplicationTypeRequirements < ActiveRecord::Migration[7.2]
  def change
    create_table :application_type_requirements do |t|
      t.references :application_type
      t.references :local_authority_requirement, null: false, foreign_key: true
      t.timestamps
    end
  end
end
