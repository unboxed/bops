# frozen_string_literal: true

class MigrateDeterminationPeriodDaysFromApplicationTypeOverridesToApplicationTypes < ActiveRecord::Migration[7.2]
  class LocalAuthority < ActiveRecord::Base; end
  class ApplicationType < ActiveRecord::Base; end

  def change
    up_only do
      LocalAuthority.find_each do |local_authority|
        next unless local_authority.application_type_overrides.is_a?(Array)

        local_authority.application_type_overrides.each do |override|
          next unless override["code"] && override["determination_period_days"]

          application_type = ApplicationType.find_by(code: override["code"].to_s, local_authority_id: local_authority.id)

          application_type&.update_column(:determination_period_days, override["determination_period_days"])
        end
      end
    end
  end
end
