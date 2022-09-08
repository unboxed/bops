# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[6.1]
  def change
    create_table :comments do |t|
      t.text :text, null: false
      t.references :user
      t.references :policy
      t.timestamps
    end
  end
end
