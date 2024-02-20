# frozen_string_literal: true

class AddPlanningConditionsToApplicationTypeFeature < ActiveRecord::Migration[7.1]
  class ApplicationType < ActiveRecord::Base; end

  def change
    up_only do
      ApplicationType.find_each do |type|
        if type.name == "planning_permission"
          type.update!(features: type.features.merge("planning_conditions" => true))
        else
          type.update!(features: type.features.merge("planning_conditions" => false))
        end
      end
    end
  end
end
