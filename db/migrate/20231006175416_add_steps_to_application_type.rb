# frozen_string_literal: true

class AddStepsToApplicationType < ActiveRecord::Migration[7.0]
  class PlanningApplication < ActiveRecord::Base
    belongs_to :application_type
    has_one :consultation, required: false
  end

  class ApplicationType < ActiveRecord::Base
    has_many :planning_applications

    def consultation?
      steps.include?("consultation")
    end
  end

  def change
    add_column :application_types, :steps, :string, array: true, default: %w[validation consultation assessment review]
    remove_index :consultations, :planning_application_id
    add_index :consultations, :planning_application_id, unique: true

    up_only do
      ApplicationType.reset_column_information
      ApplicationType.where(name: "lawfulness_certificate").update_all(steps: %w[validation assessment review])

      PlanningApplication.find_each do |planning_application|
        application_type = planning_application.application_type

        if application_type.consultation? && planning_application.consultation.blank?
          planning_application.create_consultation!
        end
      end
    end
  end
end
