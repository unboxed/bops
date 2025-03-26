# frozen_string_literal: true

class AddSubmisionGuidanceUrlToLocalAuthority < ActiveRecord::Migration[7.2]
  def change
    add_column :local_authorities, :submission_guidance_url, :string
  end
end
