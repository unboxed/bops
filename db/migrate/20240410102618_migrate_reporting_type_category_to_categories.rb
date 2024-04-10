# frozen_string_literal: true

class MigrateReportingTypeCategoryToCategories < ActiveRecord::Migration[7.1]
  class ReportingType < ActiveRecord::Base; end

  def change
    add_column :reporting_types, :categories, :string, array: true
    change_column_null :reporting_types, :category, true

    up_only do
      ReportingType.reset_column_information

      ReportingType.find_each do |type|
        type.update!(categories: [type.category])
      end

      change_column_default :reporting_types, :categories, []
      change_column_null :reporting_types, :categories, false
    end
  end
end
