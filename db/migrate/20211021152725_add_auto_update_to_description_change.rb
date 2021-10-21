# frozen_string_literal: true

class AddAutoUpdateToDescriptionChange < ActiveRecord::Migration[6.1]
  def change
    add_column :description_change_validation_requests, :auto_closed, :boolean
  end
end
