# frozen_string_literal: true

class AddLetterCopySentAtToConsultations < ActiveRecord::Migration[7.0]
  def change
    add_column :consultations, :letter_copy_sent_at, :datetime
  end
end
