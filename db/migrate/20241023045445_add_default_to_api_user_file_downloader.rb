# frozen_string_literal: true

class AddDefaultToApiUserFileDownloader < ActiveRecord::Migration[7.1]
  def change
    change_column_default(:api_users, :file_downloader, from: nil, to: {type: "NoAuthentication"})

    up_only do
      safety_assured do
        execute <<~SQL
          UPDATE api_users
          SET file_downloader = '{"type": "NoAuthentication"}'
          WHERE file_downloader IS NULL
        SQL
      end
    end
  end
end
