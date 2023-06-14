# frozen_string_literal: true

class AddEndDateToConsultations < ActiveRecord::Migration[7.0]
  def change
    add_column :consultations, :end_date, :datetime
  end
end
