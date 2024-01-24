# frozen_string_literal: true

class AddIndexToApiUserName < ActiveRecord::Migration[7.0]
  def change
    add_index :api_users, [:local_authority_id, :name], unique: true
    remove_index :api_users, name: "index_api_users_on_name_and_local_authority_id", column: [:name, :local_authority_id], unique: true, if_exists: true

    add_index :api_users, [:local_authority_id, :token], unique: true
    remove_index :api_users, name: "index_api_users_on_token_and_local_authority_id", column: [:token, :local_authority_id], unique: true, if_exists: true
  end
end
