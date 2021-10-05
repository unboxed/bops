# frozen_string_literal: true

class AddSequenceToDescriptionChangeRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :description_change_requests, :sequence, :integer
  end
end
