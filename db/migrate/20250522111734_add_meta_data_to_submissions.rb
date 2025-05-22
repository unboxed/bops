# frozen_string_literal: true

class AddMetaDataToSubmissions < ActiveRecord::Migration[7.2]
  def change
    add_column :submissions, :metadata, :jsonb, default: {}, null: false
  end
end
