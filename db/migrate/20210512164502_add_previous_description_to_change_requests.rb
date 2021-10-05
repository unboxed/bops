# frozen_string_literal: true

class AddPreviousDescriptionToChangeRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :description_change_requests, :previous_description, :string
  end
end
