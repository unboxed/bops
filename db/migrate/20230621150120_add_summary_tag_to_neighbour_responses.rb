# frozen_string_literal: true

class AddSummaryTagToNeighbourResponses < ActiveRecord::Migration[7.0]
  def change
    add_column :neighbour_responses, :summary_tag, :string
  end
end
