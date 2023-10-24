# frozen_string_literal: true

class AddRedactedByToNeighbourResponses < ActiveRecord::Migration[7.0]
  def change
    add_reference :neighbour_responses, :redacted_by, references: :users, foreign_key: {to_table: :users}
  end
end
