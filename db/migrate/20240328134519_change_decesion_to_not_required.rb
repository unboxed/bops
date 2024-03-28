# frozen_string_literal: true

class ChangeDecesionToNotRequired < ActiveRecord::Migration[7.1]
  class PlanningApplication < ActiveRecord::Base; end

  def change
    reversible do |dir|
      dir.up do
        PlanningApplication.find_each do |pa|
          next unless pa.decision == "granted_not_required"

          pa.update!(decision: "not_required")
        end
      end

      dir.down do
        PlanningApplication.find_each do |pa|
          next unless pa.decision == "not_required"

          pa.update!(decision: "granted_not_required")
        end
      end
    end
  end
end
