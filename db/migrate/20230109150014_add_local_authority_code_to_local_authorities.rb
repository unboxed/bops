# frozen_string_literal: true

class AddLocalAuthorityCodeToLocalAuthorities < ActiveRecord::Migration[6.1]
  def up
    add_column :local_authorities, :council_code, :string, unique: true

    LocalAuthority.find_each do |local_authority|
      case local_authority.subdomain
      when "buckinghamshire"
        local_authority.update(council_code: "BUC")
      when "lambeth"
        local_authority.update(council_code: "LBH")
      when "ripa"
        local_authority.update(council_code: "RIPA")
      when "southwark"
        local_authority.update(council_code: "SWK")
      else
        raise "Did not update the council code for local authority: #{local_authority.subdomain}"
      end
    end

    change_column_null :local_authorities, :council_code, false
  end

  def down
    remove_column :local_authorities, :council_code
  end
end
