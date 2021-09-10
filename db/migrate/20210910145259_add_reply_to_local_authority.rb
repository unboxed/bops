class AddReplyToLocalAuthority < ActiveRecord::Migration[6.1]
  class LocalAuthority < ApplicationRecord; end
  
  def change
    add_column :local_authorities, :reply_to_notify_id, :string
  
    reversible do |dir|
      dir.up do
        LocalAuthority.find_each do |authority|
          authority.update(reply_to_notify_id: "f755c178-b01a-4323-a756-d669e9350c33") if authority.subdomain == "southwark"
          authority.update(reply_to_notify_id: "5fe1d483-9bbe-4b56-8e71-8ce193fef723") if authority.subdomain == "lambeth"
          authority.update(reply_to_notify_id: "4896bb50-4f4c-4b4d-ad67-2caddddde125") if authority.subdomain == "buckinghamshire"
        end
      end
    end
  end
end
