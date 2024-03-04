# frozen_string_literal: true

class AddExpiryDateToPressAndSiteNotices < ActiveRecord::Migration[7.1]
  def change
    add_column :press_notices, :expiry_date, :date
    add_column :site_notices, :expiry_date, :date

    up_only do
      execute <<~SQL
        UPDATE press_notices AS p
        SET expiry_date = c.end_date
        FROM consultations AS c
        WHERE p.planning_application_id = c.planning_application_id
        AND p.published_at IS NOT NULL
      SQL

      execute <<~SQL
        UPDATE site_notices AS s
        SET expiry_date = c.end_date
        FROM consultations AS c
        WHERE s.planning_application_id = c.planning_application_id
        AND s.displayed_at IS NOT NULL
      SQL
    end
  end
end
