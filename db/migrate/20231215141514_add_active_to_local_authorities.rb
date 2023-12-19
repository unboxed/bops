# frozen_string_literal: true

class AddActiveToLocalAuthorities < ActiveRecord::Migration[7.0]
  def up
    add_column :local_authorities, :active, :boolean, null: false, default: false

    active_authorities = %w[southwark lambeth buckinghamshire camden plan_x]

    LocalAuthority.find_each do |authority|
      authority.update(active: true) if active_authorities.include?(authority.subdomain)
    end
  end

  def down
    remove_column :local_authorities, :active
  end
end
