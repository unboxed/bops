# frozen_string_literal: true

class AddArrayTrueToTags < ActiveRecord::Migration[7.1]
  def change
    add_column :neighbour_responses, :tags1, :string, array: true, default: []

    NeighbourResponse.all.find_each do |response|
      response.tags.each { |tag| response.tags1 << tag }
      response.save!(validate: false)
    end

    remove_column :neighbour_responses, :tags, :jsonb
    rename_column :neighbour_responses, :tags1, :tags
  end
end
