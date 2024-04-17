# frozen_string_literal: true

class DropCategoryFromReportingType < ActiveRecord::Migration[7.1]
  class ReportingType < ActiveRecord::Base; end

  def up
    safety_assured { remove_column :reporting_types, :category }
  end

  def down
    add_column :reporting_types, :category, :string

    ReportingType.reset_column_information

    ReportingType.find_each do |type|
      type.update!(category: type.categories.first)
    end
  end
end
