# frozen_string_literal: true

class AddDeterminationPeriodDaysToLocalAuthorityApplicationType < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :local_authority_application_types, :determination_period_days, :integer

    reversible do |dir|
      dir.up do
        application_types = ApplicationType.pluck(:code, :id).to_h

        LocalAuthority.find_each do |local_authority|
          next if local_authority.application_type_overrides.blank?

          local_authority.application_type_overrides.each do |override|
            application_type_id = application_types[override["code"]]
            next unless application_type_id

            lap = LocalAuthority::ApplicationType.find_or_initialize_by(
              local_authority_id: local_authority.id,
              application_type_id: application_type_id
            )

            if lap.new_record? || lap.determination_period_days != override["determination_period_days"]
              lap.update!(determination_period_days: override["determination_period_days"])
            end
          end
        end
      end
    end
  end
end
