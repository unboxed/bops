# frozen_string_literal: true

class AddConsulteeReplyAddressToConsultations < ActiveRecord::Migration[7.0]
  class LocalAuthority < ActiveRecord::Base; end

  def change
    add_column :local_authorities, :email_reply_to_id, :uuid
    add_column :consultations, :consultee_email_reply_to_id, :uuid

    up_only do
      uuids = [
        %w[lambeth 5fe1d483-9bbe-4b56-8e71-8ce193fef723],
        %w[southwark f755c178-b01a-4323-a756-d669e9350c33],
        %w[buckinghamshire 4896bb50-4f4c-4b4d-ad67-2caddddde125]
      ]

      uuids.each do |subdomain, uuid|
        LocalAuthority.where(subdomain:).update_all(email_reply_to_id: uuid)
      end
    end
  end
end
