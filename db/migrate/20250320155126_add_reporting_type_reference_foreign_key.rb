# frozen_string_literal: true

class AddReportingTypeReferenceForeignKey < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :planning_applications, :reporting_types, column: :reporting_type_id, validate: false
  end
end
