# frozen_string_literal: true

class AddRedactedResponseToNeighbourResponse < ActiveRecord::Migration[7.0]
  def change
    add_column :neighbour_responses, :redacted_response, :text
  end
end
