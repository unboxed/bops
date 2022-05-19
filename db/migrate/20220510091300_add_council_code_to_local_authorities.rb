# frozen_string_literal: true

class AddCouncilCodeToLocalAuthorities < ActiveRecord::Migration[6.1]
  class LocalAuthority < ApplicationRecord; end

  def up
    add_column :local_authorities, :council_code, :string, unique: true

    LocalAuthority.find_each do |local_authority|
      case local_authority.subdomain
      when "lambeth"
        local_authority.update(council_code: "LBH")
      when "southwark"
        local_authority.update(council_code: "SWK")
      when "buckinghamshire"
        local_authority.update(council_code: "BUC")
      else
        raise "Did not update the council code for local authority: #{local_authority.name}"
      end
    end

    change_column_null :local_authorities, :council_code, false
  end

  def down
    remove_column :local_authorities, :council_code, :string
  end
end
