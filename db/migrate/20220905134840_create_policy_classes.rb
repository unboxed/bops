# frozen_string_literal: true

class CreatePolicyClasses < ActiveRecord::Migration[6.1]
  def up
    create_table :policy_classes do |t|
      t.string :schedule, null: false
      t.integer :part, null: false
      t.string :section, null: false
      t.string :url
      t.string :name, null: false
      t.references :planning_application
      t.timestamps
    end

    create_table :policies do |t|
      t.string :section, null: false
      t.string :description, null: false
      t.integer :status, null: false
      t.references :policy_class
      t.timestamps
    end

    rename_column :planning_applications, :policy_classes, :policy_classes_bak

    PlanningApplication.find_each do |planning_application|
      planning_application.policy_classes_bak.each do |policy_class_attributes|
        policy_class = PolicyClass.create!(
          planning_application:,
          schedule: "Schedule 1",
          part: policy_class_attributes["part"],
          section: policy_class_attributes["id"],
          url: policy_class_attributes["url"],
          name: policy_class_attributes["name"]
        )

        policy_class_attributes["policies"].each do |policy_attributes|
          Policy.create!(
            policy_class:,
            section: policy_attributes["id"],
            description: policy_attributes["description"],
            status: policy_attributes["status"]
          )
        end
      end
    end
  end

  def down
    drop_table :policies
    drop_table :policy_classes
    rename_column :planning_applications, :policy_classes_bak, :policy_classes
  end
end
