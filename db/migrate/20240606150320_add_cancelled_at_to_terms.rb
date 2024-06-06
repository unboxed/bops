# frozen_string_literal: true

class AddCancelledAtToTerms < ActiveRecord::Migration[7.1]
  def change
    add_column :terms, :cancelled_at, :datetime

    up_only do
      Term.find_each do |term|
        term.update!(cancelled_at: Time.zone.now) if term.validation_requests.where(state: "cancelled").any?
      end
    end
  end
end
