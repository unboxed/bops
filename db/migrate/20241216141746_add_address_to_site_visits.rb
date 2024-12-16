# frozen_string_literal: true

class AddAddressToSiteVisits < ActiveRecord::Migration[7.2]
  def change
    add_column :site_visits, :address, :string
  end
end
