# frozen_string_literal: true

class AddTagsToNeighbourResponses < ActiveRecord::Migration[7.0]
  def change
    add_column :neighbour_responses, :tags, :jsonb, default: [], null: false
  end
end
