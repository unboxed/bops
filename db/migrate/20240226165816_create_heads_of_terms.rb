# frozen_string_literal: true

class CreateHeadsOfTerms < ActiveRecord::Migration[7.1]
  def change
    create_table :heads_of_terms do |t|
      t.references :planning_application
      t.timestamps
    end

    create_table :terms do |t|
      t.string :title, null: false
      t.text :text, null: false
      t.references :heads_of_term
      t.timestamps
    end
  end
end
