# frozen_string_literal: true

class AddSiteNoticeConfigToLocalAuthority < ActiveRecord::Migration[8.0]
  def change
    add_column :local_authorities, :site_notice_logo, :string
    add_column :local_authorities, :site_notice_phone_number, :string
    add_column :local_authorities, :site_notice_email_address, :string
    add_column :local_authorities, :site_notice_show_assigned_officer, :boolean, null: false, default: false
  end
end
