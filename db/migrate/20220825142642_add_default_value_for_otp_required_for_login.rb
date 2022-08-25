# frozen_string_literal: true

class AddDefaultValueForOtpRequiredForLogin < ActiveRecord::Migration[6.1]
  def up
    change_column_default :users, :otp_required_for_login, true

    execute(
      "UPDATE users
      SET otp_required_for_login = TRUE
      WHERE otp_required_for_login IS NULL;"
    )

    change_column_null :users, :otp_required_for_login, false
  end

  def down
    change_column_default :users, :otp_required_for_login, nil
    change_column_null :users, :otp_required_for_login, true
  end
end
