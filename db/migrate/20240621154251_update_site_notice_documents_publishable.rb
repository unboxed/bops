# frozen_string_literal: true

class UpdateSiteNoticeDocumentsPublishable < ActiveRecord::Migration[7.1]
  def change
    up_only do
      SiteNotice.find_each do |site_notice|
        site_notice.documents.each do |document|
          document.update!(publishable: true) if site_notice.required?
        end
      end
    end
  end
end
