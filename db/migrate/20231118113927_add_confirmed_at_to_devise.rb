# frozen_string_literal: true

class AddConfirmedAtToDevise < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime

    User.all.find_each do |user|
      user.update(
        confirmed_at: Time.zone.now
      )
    end
  end
end
