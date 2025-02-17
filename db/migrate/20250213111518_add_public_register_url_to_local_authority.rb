# frozen_string_literal: true

class AddPublicRegisterUrlToLocalAuthority < ActiveRecord::Migration[7.2]
  def change
    add_column :local_authorities, :public_register_base_url, :string
  end
end
