# frozen_string_literal: true

class SiteNotice < ApplicationRecord
  belongs_to :planning_application
  has_one :document

  attr_reader :method

  def preview_content
    I18n.t("site_notice_template")
  end
end
