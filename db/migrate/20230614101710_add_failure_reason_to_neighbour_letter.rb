# frozen_string_literal: true

class AddFailureReasonToNeighbourLetter < ActiveRecord::Migration[7.0]
  def change
    add_column :neighbour_letters, :failure_reason, :string
  end
end
