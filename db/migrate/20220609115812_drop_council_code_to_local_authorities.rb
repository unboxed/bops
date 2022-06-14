# frozen_string_literal: true

class DropCouncilCodeToLocalAuthorities < ActiveRecord::Migration[6.1]
  def up
    remove_column :local_authorities, :council_code
  end

  def down
    add_column :local_authorities, :council_code, :string, unique: true

    LocalAuthority.find_each do |local_authority|
      case local_authority.subdomain
      when "lambeth"
        local_authority.update(council_code: "LBH")
      when "southwark"
        local_authority.update(council_code: "SWK")
      when "buckinghamshire"
        local_authority.update(council_code: "BUC")
      when "ripa"
        local_authority.update(council_code: "RIPA")
      else
        raise "Did not update the council code for local authority: #{local_authority.name}"
      end
    end

    change_column_null :local_authorities, :council_code, false
  end
end
