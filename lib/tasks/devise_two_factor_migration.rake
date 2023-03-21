# frozen_string_literal: true

# lib/tasks/devise_two_factor_migration.rake

# Use this as a starting point for your task to migrate your user's OTP secrets.
namespace :devise_two_factor do
  desc "Copy devise_two_factor OTP secret from old format to new format"
  task copy_otp_secret_to_rails7_encrypted_attr: [:environment] do
    # TODO: change User to your user model
    User.find_each do |user| # find_each finds in batches of 1,000 by default
      otp_secret = user.otp_secret # read from otp_secret column, fall back to legacy columns if new column is empty
      puts "Processing #{user.email}"
      user.update!(otp_secret:)
    end
  end
end
