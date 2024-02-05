# frozen_string_literal: true

class ChangeEvidenceGroupStartEndDateToDate < ActiveRecord::Migration[7.1]
  def up
    change_table :evidence_groups, bulk: true do |t|
      t.change :start_date, :date
      t.change :end_date, :date
    end
  end

  def down
    change_table :evidence_groups, bulk: true do |t|
      t.change :start_date, :datetime
      t.change :end_date, :datetime
    end
  end
end
