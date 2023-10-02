# frozen_string_literal: true

class AddPressNoticeEmailToLocalAuthorities < ActiveRecord::Migration[7.0]
  def change
    add_column :local_authorities, :press_notice_email, :string
  end
end
