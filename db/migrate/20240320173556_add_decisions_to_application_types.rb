# frozen_string_literal: true

class AddDecisionsToApplicationTypes < ActiveRecord::Migration[7.1]
  class ApplicationType < ActiveRecord::Base; end

  def change
    add_column :application_types, :decision_set, :jsonb

    up_only do
      ApplicationType.find_each do |type|
        decision_set = if type.suffix == "PA"
          {decisions: %w[granted granted_not_required refused]}
        else
          {decisions: %w[granted refused]}
        end
        type.update!(decision_set: decision_set)
      end

      change_column_null :application_types, :decision_set, false, {}
      change_column_default :application_types, :decision_set, from: nil, to: {}
    end
  end
end
