# frozen_string_literal: true

class AddLastResponseAtToConsultees < ActiveRecord::Migration[7.0]
  def change
    add_column :consultees, :last_response_at, :datetime
  end
end
