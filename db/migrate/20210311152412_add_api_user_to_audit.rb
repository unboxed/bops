class AddApiUserToAudit < ActiveRecord::Migration[6.0]
  def change
    add_reference(:audits, :api_user, foreign_key: true)
  end
end
