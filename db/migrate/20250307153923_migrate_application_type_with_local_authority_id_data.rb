# frozen_string_literal: true

class MigrateApplicationTypeWithLocalAuthorityIdData < ActiveRecord::Migration[7.2]
  class ApplicationType < ActiveRecord::Base; end
  class LocalAuthority < ActiveRecord::Base; end

  def change
    up_only do
      ApplicationType.where(local_authority_id: nil).find_each do |application_type|
        LocalAuthority.all.find_each do |local_authority|
          ApplicationType.create!(application_type.attributes.except("id").merge(config_id: application_type.id, local_authority_id: local_authority.id))
        end
      end
    end
  end
end
