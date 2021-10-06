# frozen_string_literal: true

class CreateInitialSchema < ActiveRecord::Migration[6.0]
  def change
    ############################################################################
    # Sites
    ############################################################################
    create_table :sites do |t|
      t.string :address_1, null: true
      t.string :address_2, null: true
      t.string :town, null: true
      t.string :county, null: true
      t.string :postcode, null: true

      t.timestamps
    end

    ############################################################################
    # Planning Applications
    ############################################################################
    create_table :planning_applications do |t|
      t.date :submission_date, null: false
      t.integer :application_type, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.datetime :started_at, null: true
      t.datetime :completed_at, null: true
      t.text :description, null: true
      t.references :site, null: false

      t.timestamps
    end

    ############################################################################
    # Decisions
    ############################################################################
    create_table :decisions do |t|
      t.integer :status, default: 0, null: false
      t.datetime :decided_at, null: true
      t.references :planning_application, null: false
      t.references :user, null: false

      t.timestamps
    end
  end
end
