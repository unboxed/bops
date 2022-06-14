# frozen_string_literal: true

class DropNameToLocalAuthorities < ActiveRecord::Migration[6.1]
  def up
    remove_column :local_authorities, :name
  end

  def down
    add_column :local_authorities, :name, :string

    LocalAuthority.find_each do |local_authority|
      case local_authority.subdomain
      when "lambeth"
        local_authority.update(name: "Lambeth Council Authority")
      when "southwark"
        local_authority.update(name: "Southwark Council Authority")
      when "buckinghamshire"
        local_authority.update(name: "Buckinghamshire Council Authority")
      when "ripa"
        local_authority.update(name: "Ripa")
      else
        raise "Did not update the council code for local authority: #{local_authority.name}"
      end
    end

    change_column_null :local_authorities, :name, false
  end
end
