# frozen_string_literal: true

class UpdateUniqueIndexesOnApiUser < ActiveRecord::Migration[7.0]
  class LocalAuthority < ActiveRecord::Base
    has_many :api_users
  end

  class ApiUser < ActiveRecord::Base
    belongs_to :local_authority, optional: true

    has_secure_token :token, length: 36
  end

  def up
    remove_index :api_users, :name
    remove_index :api_users, :token

    add_index :api_users, [:name, :local_authority_id], unique: true, name: "index_api_users_on_name_and_local_authority_id"
    add_index :api_users, [:token, :local_authority_id], unique: true, name: "index_api_users_on_token_and_local_authority_id"

    planx = ApiUser.find_or_create_by!(name: "PlanX")
    LocalAuthority.find_each do |authority|
      authority.api_users.create!(name: planx.name, token: planx.token)
    end

    # We do not want to create swagger api user tokens for production
    unless Bops.env.production?
      swagger = ApiUser.find_or_create_by!(name: "swagger")
      LocalAuthority.find_each do |authority|
        authority.api_users.create!(name: swagger.name, token: swagger.token)
      end
    end
  end

  def down
    LocalAuthority.find_each do |authority|
      authority.api_users.where(name: "PlanX").delete_all
      authority.api_users.where(name: "swagger").delete_all
    end

    remove_index :api_users, name: "index_api_users_on_name_and_local_authority_id"
    remove_index :api_users, name: "index_api_users_on_token_and_local_authority_id"

    add_index :api_users, :name, unique: true
    add_index :api_users, :token, unique: true
  end
end
