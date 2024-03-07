# frozen_string_literal: true

class AddTelephoneNumberToLocalAuthority < ActiveRecord::Migration[7.1]
  def change
    add_column :local_authorities, :telephone_number, :string
  end
end
