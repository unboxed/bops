# frozen_string_literal: true

class ChangeImmunityDetailsEndDateToDate < ActiveRecord::Migration[7.1]
  def up
    change_table :immunity_details, bulk: true do |t|
      t.change :end_date, :date
    end
  end

  def down
    change_table :immunity_details, bulk: true do |t|
      t.change :end_date, :datetime
    end
  end
end
