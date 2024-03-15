# frozen_string_literal: true

class AddDeterminationPeriodDaysToApplicationTypes < ActiveRecord::Migration[7.1]
  def change
    add_column :application_types, :determination_period_days, :integer
  end
end
