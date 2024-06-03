# frozen_string_literal: true

module ActiveStorage
  module Authorize
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_user!, unless: :public?
    end

    def public?
      return if @blob.nil?

      attachments = if @blob.attachments.count == 1 && @blob.attachments.any? { |a| a.record_type == "ActiveStorage::VariantRecord" }
        @blob.attachments.first.record.blob.attachments.first.record.attachments
      else
        @blob.attachments
      end

      attachments.includes(:record).any? { |a| a.record&.published? }
    end
  end
end
