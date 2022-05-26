# frozen_string_literal: true

class AddNotNullConstraintsToLocalAuthorities < ActiveRecord::Migration[6.1]
  def change
    change_column_null :local_authorities, :name, false
    change_column_null :local_authorities, :subdomain, false
  end
end
