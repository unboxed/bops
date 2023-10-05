# frozen_string_literal: true

class AddNeighbourToSiteVisit < ActiveRecord::Migration[7.0]
  def change
    add_reference :site_visits, :neighbour, foreign_key: true
  end
end
