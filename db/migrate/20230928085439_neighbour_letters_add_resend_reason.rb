# frozen_string_literal: true

class NeighbourLettersAddResendReason < ActiveRecord::Migration[7.0]
  def change
    add_column :neighbour_letters, :resend_reason, :string
  end
end
