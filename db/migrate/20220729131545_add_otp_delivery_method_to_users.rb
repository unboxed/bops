# frozen_string_literal: true

class AddOtpDeliveryMethodToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :otp_delivery_method, :integer, default: 0
  end
end
