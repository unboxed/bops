# frozen_string_literal: true

class AddTimeStampReceivedAtToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :received_at, :timestamp
  end
end
