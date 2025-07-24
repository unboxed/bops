# frozen_string_literal: true

class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks, id: :uuid do |t|
      t.references :parent, polymorphic: true, null: false, type: :uuid
      t.string :name, null: false
      t.string :status, default: "not_started"
      t.string :slug, null: false
      t.boolean :optional, default: false, null: false
      t.integer :position
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :tasks, [:parent_type, :parent_id, :name], unique: true, name: "index_tasks_on_parent_and_name"
    add_index :tasks, [:parent_type, :parent_id, :slug], name: "index_tasks_on_parent_and_slug"
  end
end
