# frozen_string_literal: true

class AddEiaInformationToPlanningApplication < ActiveRecord::Migration[7.0]
  class EnvironmentImpactAssessment < ActiveRecord::Base
    belongs_to :planning_application
  end

  def change
    create_table "environment_impact_assessments", force: :cascade do |t|
      t.references :planning_application, null: false
      t.string :address
      t.integer :fee
      t.boolean :required, null: false, default: true
      t.timestamps
    end

    PlanningApplication.where(environment_impact_assessment: true).find_each do |planning_application|
      EnvironmentImpactAssessment.create(planning_application:, required: true)
    end

    PlanningApplication.where(environment_impact_assessment: false).find_each do |planning_application|
      EnvironmentImpactAssessment.create(planning_application:, required: false)
    end

    remove_column :planning_applications, :environment_impact_assessment, :boolean
  end
end
