# frozen_string_literal: true

class AddApplicationTypeOverridesToLocalAuthority < ActiveRecord::Migration[7.2]
  def change
    add_column :local_authorities, :application_type_overrides, :jsonb
  end
end
