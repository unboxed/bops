# frozen_string_literal: true

class AddMagicLinkLastSentAtToConsultees < ActiveRecord::Migration[7.2]
  def change
    add_column :consultees, :magic_link_last_sent_at, :datetime
  end
end
