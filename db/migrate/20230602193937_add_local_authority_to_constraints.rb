# frozen_string_literal: true

class AddLocalAuthorityToConstraints < ActiveRecord::Migration[7.0]
  def change
    add_reference :constraints, :local_authority, index: true
  end
end
