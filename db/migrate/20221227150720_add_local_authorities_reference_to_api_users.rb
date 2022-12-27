# frozen_string_literal: true

class AddLocalAuthoritiesReferenceToApiUsers < ActiveRecord::Migration[6.1]
  def change
    add_reference :api_users, :local_authority, index: true
  end
end
