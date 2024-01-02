# frozen_string_literal: true

class AddNoticeReasonToLandOwner < ActiveRecord::Migration[7.0]
  def change
    add_column :land_owners, :notice_reason, :string
  end
end
