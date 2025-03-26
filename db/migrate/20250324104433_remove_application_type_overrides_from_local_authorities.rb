# frozen_string_literal: true

class RemoveApplicationTypeOverridesFromLocalAuthorities < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      remove_column :local_authorities, :application_type_overrides, :jsonb
    end
  end
end
