# frozen_string_literal: true

class CreateApplicationType < ActiveRecord::Migration[7.0]
  class ApplicationType < ApplicationRecord
  end

  def up
    create_table :application_types do |t|
      t.string :name, null: false
      t.integer :part
      t.string :section
      t.timestamps
    end

    add_reference :planning_applications, :application_type

    lawful = ApplicationType.create(
      name: "lawfulness_certificate"
    )

    prior = ApplicationType.create(
      name: "prior_approval",
      part: 1,
      section: "A"
    )

    PlanningApplication.find_each do |application|
      type = ((application.application_type == "lawfulness_certificate") ? lawful : prior)
      application.update(application_type_id: type.id)
    end

    remove_column :planning_applications, :application_type
  end

  def down
    add_column :planning_applications, :application_type, :integer

    PlanningApplication.find_each do |application|
      type = application.planning_application_type_id
      application.update(application_type: type)
    end

    remove_column :planning_applications, :application_type_id

    drop_table :application_types
  end
end
