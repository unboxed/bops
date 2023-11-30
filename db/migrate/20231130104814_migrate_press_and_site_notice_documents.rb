# frozen_string_literal: true

class MigratePressAndSiteNoticeDocuments < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL
      UPDATE documents
      SET owner_id = press_notice_id, owner_type = 'PressNotice', press_notice_id = NULL
      WHERE press_notice_id IS NOT NULL
    SQL

    execute <<~SQL
      UPDATE documents
      SET owner_id = site_notice_id, owner_type = 'SiteNotice', site_notice_id = NULL
      WHERE site_notice_id IS NOT NULL
    SQL
  end

  def down
    execute <<~SQL
      UPDATE documents
      SET press_notice_id = owner_id, owner_id = NULL, owner_type = NULL
      WHERE owner_type = 'PressNotice'
    SQL

    execute <<~SQL
      UPDATE documents
      SET site_notice_id = owner_id, owner_id = NULL, owner_type = NULL
      WHERE owner_type = 'SiteNotice'
    SQL
  end
end
