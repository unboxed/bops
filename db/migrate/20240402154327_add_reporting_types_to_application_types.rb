class AddReportingTypesToApplicationTypes < ActiveRecord::Migration[7.1]
  class ApplicationType < ActiveRecord::Base; end

  def change
    add_column :application_types, :reporting_types, :string, array: true

    up_only do
      ApplicationType.find_each do |type|
        type.update!(reporting_types: [])
      end

      change_column_default :application_types, :reporting_types, []
      change_column_null :application_types, :reporting_types, false
    end
  end
end
