# frozen_string_literal: true

class UpdateSiteNoticeDocumentsPublishable < ActiveRecord::Migration[7.1]
  class Document < ActiveRecord::Base; end
  class SiteNotice < ActiveRecord::Base; end
  SiteNotice.has_many :documents

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
