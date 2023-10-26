# frozen_string_literal: true

class UpdateSouthwarkReplyToAddress < ActiveRecord::Migration[7.0]
  class LocalAuthority < ActiveRecord::Base; end

  def up
    LocalAuthority.find_by!(subdomain: "southwark").tap do |local_authority|
      local_authority.update!(email_reply_to_id: "47de5588-2e37-4c1c-ae56-e80a5de0f9c6")
    end
  end

  def down
    LocalAuthority.find_by!(subdomain: "southwark").tap do |local_authority|
      local_authority.update!(email_reply_to_id: "f755c178-b01a-4323-a756-d669e9350c33")
    end
  end
end
