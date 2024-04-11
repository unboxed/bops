# frozen_string_literal: true

class AddDecisionsToApplicationTypes < ActiveRecord::Migration[7.1]
  class ApplicationType < ActiveRecord::Base; end

  def change
    add_column :application_types, :decisions, :string, array: true

    up_only do
      ApplicationType.reset_column_information

      ApplicationType.find_each do |type|
        case type.category
        when "certificate-of-lawfulness"
          type.update!(decisions: %w[granted refused])
        when "prior-approval"
          type.update!(decisions: %w[granted not_required refused])
        when "householder"
          type.update!(decisions: %w[granted refused])
        when "full"
          type.update!(decisions: %w[granted refused])
        else
          type.update!(decisions: [])
        end
      end

      change_column_default :application_types, :decisions, []
      change_column_null :application_types, :decisions, false
    end
  end
end
