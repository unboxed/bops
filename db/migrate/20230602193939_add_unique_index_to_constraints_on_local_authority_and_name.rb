# frozen_string_literal: true

class AddUniqueIndexToConstraintsOnLocalAuthorityAndName < ActiveRecord::Migration[7.0]
  def change
    add_index :constraints, %i[local_authority_id name], unique: true
  end
end
