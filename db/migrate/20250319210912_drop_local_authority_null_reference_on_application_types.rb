# frozen_string_literal: true

class DropLocalAuthorityNullReferenceOnApplicationTypes < ActiveRecord::Migration[7.2]
  class ApplicationType < ActiveRecord::Base; end

  def change
    up_only do
      ApplicationType.where(local_authority_id: nil).delete_all
    end
  end
end
