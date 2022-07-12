# frozen_string_literal: true

class AddAutoClosedAtToDescriptionChangeValidationRequests < ActiveRecord::Migration[6.1]
  class DescriptionChangeValidationRequest < ApplicationRecord
    scope :auto_closed, -> { where(auto_closed: true) }
  end

  def change
    add_column :description_change_validation_requests, :auto_closed_at, :datetime

    DescriptionChangeValidationRequest.auto_closed.find_each do |request|
      request.update(auto_closed_at: request.updated_at)
    end
  end
end
