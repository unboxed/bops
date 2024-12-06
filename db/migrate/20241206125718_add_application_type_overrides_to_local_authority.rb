# frozen_string_literal: true

class AddApplicationTypeOverridesToLocalAuthority < ActiveRecord::Migration[7.2]
  def change
    add_column :local_authorities, :application_type_overrides, :jsonb, default: []

    up_only do
      LocalAuthority.reset_column_information

      LocalAuthority.find_each do |local_authority|
        local_authority.update!(application_type_overrides: [{"code" => "preApp", "determination_period_days" => 30}])
      end
    end
  end
end
