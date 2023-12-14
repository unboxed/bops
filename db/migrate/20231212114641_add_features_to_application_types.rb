# frozen_string_literal: true

class AddFeaturesToApplicationTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :application_types, :features, :jsonb, default: {}

    up_only do
      ApplicationType.reset_column_information

      ApplicationType.find_each do |application_type|
        if application_type.name == "planning_permission"
          application_type.update!(features: {"permitted_development_rights" => false})
        end
      end
    end
  end
end
