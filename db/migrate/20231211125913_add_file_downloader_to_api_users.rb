# frozen_string_literal: true

class AddFileDownloaderToApiUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :api_users, :file_downloader, :jsonb
  end
end
