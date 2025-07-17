# frozen_string_literal: true

class AddConsulteesNotRequiredToConsultation < ActiveRecord::Migration[7.2]
  def change
    add_column :consultations, :consultees_not_required, :boolean, null: false, default: false
  end
end
