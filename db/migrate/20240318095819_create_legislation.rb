# frozen_string_literal: true

class CreateLegislation < ActiveRecord::Migration[7.1]
  def change
    add_column :application_types, :legislation_id, :bigint
    add_index :application_types, :legislation_id

    create_table :legislation do |t|
      t.string :title
      t.string :description
      t.string :link

      t.timestamps
    end

    add_foreign_key :application_types, :legislation
  end
end
