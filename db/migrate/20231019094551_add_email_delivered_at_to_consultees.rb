# frozen_string_literal: true

class AddEmailDeliveredAtToConsultees < ActiveRecord::Migration[7.0]
  def change
    add_column :consultees, :email_delivered_at, :datetime
  end
end
