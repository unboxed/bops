# frozen_string_literal: true

class CreateCaseRecord < ActiveRecord::Migration[7.2]
  def change
    create_table :case_records, id: false do |t|
      t.uuid :id, primary_key: true
      t.references :local_authority, null: false, foreign_key: true
      t.string :caseable_type, null: false
      t.bigint :caseable_id, null: false

      t.index [:caseable_type, :caseable_id]

      t.timestamps
    end
  end
end
