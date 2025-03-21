# frozen_string_literal: true

class EnableReportingTypeReferenceForeignKey < ActiveRecord::Migration[7.2]
  def change
    validate_foreign_key :planning_applications, :reporting_types, column: :reporting_type_id
  end
end
