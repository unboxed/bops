# frozen_string_literal: true

class AddApplicationTypeRequirementsJoinTable < ActiveRecord::Migration[8.0]
  def change
    create_table :application_types_local_authority_requirements, id: false do |t|
      t.bigint :application_type_id, null: false
      t.bigint :requirement_id, null: false
      t.index %i[application_type_id requirement_id], unique: true
      t.index %i[requirement_id]
      t.foreign_key :application_types
      t.foreign_key :local_authority_requirements, column: :requirement_id
    end

    up_only do
      safety_assured do
        execute <<~SQL
          INSERT INTO application_types_local_authority_requirements
          (application_type_id, requirement_id)
          SELECT application_type_id, local_authority_requirement_id
          FROM application_type_requirements
        SQL
      end
    end
  end
end
