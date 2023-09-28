# frozen_string_literal: true

class AddLastLetterSentAtToNeighbour < ActiveRecord::Migration[7.0]
  def change
    add_column :neighbours, :last_letter_sent_at, :datetime
  end
end
