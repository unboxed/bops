# frozen_string_literal: true

class AddPreappGuidanceUrlToLocalAuthority < ActiveRecord::Migration[8.0]
  def change
    add_column :local_authorities, :preapp_guidance_url, :string
  end
end
