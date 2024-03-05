# frozen_string_literal: true

class CreateInformatives < ActiveRecord::Migration[7.1]
  def change
    create_table :informative_sets do |t|
      t.references :planning_application
      t.timestamps
    end

    create_table :informatives do |t|
      t.string :title
      t.text :text
      t.references :informative_set
      t.timestamps
    end
  end
end
