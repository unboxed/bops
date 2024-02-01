# frozen_string_literal: true

class ChangeConsultationStartEndDateToDate < ActiveRecord::Migration[7.1]
  def up
    change_table :consultations, bulk: true do |t|
      t.change :start_date, :date
      t.change :end_date, :date
    end
  end

  def down
    change_table :consultations, bulk: true do |t|
      t.change :start_date, :datetime
      t.change :end_date, :datetime
    end
  end
end
