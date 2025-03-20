# frozen_string_literal: true

class MovePlanningApplicationsToNewApplicationTypes < ActiveRecord::Migration[7.2]
  class PlanningApplication < ActiveRecord::Base; end
  class ApplicationType < ActiveRecord::Base; end

  def change
    reversible do |dir|
      dir.up do
        ApplicationType.where.not(config_id: nil).find_each do |a|
          scope = PlanningApplication.where(
            application_type_id: a.config_id,
            local_authority_id: a.local_authority_id
          )

          scope.update_all(application_type_id: a.id)
        end
      end

      dir.down do
        ApplicationType.where.not(config_id: nil).find_each do |a|
          scope = PlanningApplication.where(
            application_type_id: a.id
          )

          scope.update_all(application_type_id: a.config_id)
        end
      end
    end
  end
end
