# frozen_string_literal: true

class MigrateApplicationTypeToApplicationTypeConfig < ActiveRecord::Migration[7.2]
  def change
    up_only do
      safety_assured do
        execute <<~SQL.squish
          INSERT INTO application_type_configs
          SELECT *
          FROM application_types;
        SQL
      end
    end
  end
end
