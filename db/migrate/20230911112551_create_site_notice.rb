# frozen_string_literal: true

class CreateSiteNotice < ActiveRecord::Migration[7.0]
  def change
    create_table :site_notices do |t|
      t.references :planning_application
      t.boolean :required
      t.text :content
      t.datetime :displayed_at
      t.timestamps
    end

    add_reference :documents, :site_notice, null: true, foreign_key: true
  end
end
