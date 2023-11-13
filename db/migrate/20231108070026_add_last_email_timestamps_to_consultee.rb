# frozen_string_literal: true

class AddLastEmailTimestampsToConsultee < ActiveRecord::Migration[7.0]
  def change
    add_column :consultees, :last_email_sent_at, :datetime
    add_column :consultees, :last_email_delivered_at, :datetime
  end
end
