# frozen_string_literal: true

class AddEnvironmentImpactAssessmentToPlanningApplications < ActiveRecord::Migration[7.0]
  def change
    add_column :planning_applications, :environment_impact_assessment, :boolean, null: true # rubocop:disable Rails/ThreeStateBooleanColumn
  end
end
