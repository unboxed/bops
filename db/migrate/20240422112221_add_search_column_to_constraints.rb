# frozen_string_literal: true

class AddSearchColumnToConstraints < ActiveRecord::Migration[7.1]
  def change
    add_column :constraints, :searchable_type_code, :string

    Constraint.find_each do |constraint|
      constraint.update(searchable_type_code: I18n.t("constraint_type_codes.#{constraint.type}", default: constraint.type.titleize.capitalize))
    end

    sql = <<~SQL.squish
      to_tsvector('simple',
        COALESCE(category, '') || ' ' ||
        COALESCE(type, '') || ' ' ||
        COALESCE(searchable_type_code, '') || ' '
      )
    SQL

    safety_assured { add_column :constraints, :search, :virtual, type: :tsvector, as: sql, stored: true }
  end
end
