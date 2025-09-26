# frozen_string_literal: true

class AddAddressToSiteHistories < ActiveRecord::Migration[8.0]
  def change
    add_column :site_histories, :address, :string
  end
end
