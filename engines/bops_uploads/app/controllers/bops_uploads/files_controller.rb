# frozen_string_literal: true

module BopsUploads
  class FilesController < ApplicationController
    before_action :set_blob
    before_action :set_parent
    before_action :raise_not_found, unless: :local_authority_matches?

    def show
      signed_cookies.each do |key, value|
        cookies[key] = {
          value: value,
          path: blob_path(@blob.key),
          expires: expiry_time
        }
      end

      redirect_to blob_url(@blob.key)
    end

    private

    def set_parent
      @parent = @blob.parent_record

      case @parent
      when CaseRecord
        @case_record = @parent
      when PlanningApplication
        @planning_application = @parent
      when Submission
        @submission = @parent
      else
        raise ArgumentError, "Unexpected parent record: #{@parent.inspect}"
      end
    end

    def local_authority_matches?
      @parent && @parent.local_authority == current_local_authority
    end

    def raise_not_found
      raise ActiveRecord::RecordNotFound, "Couldn't find ActiveStorage::Blob with 'key'=#{@blob.key}"
    end

    def signed_cookies
      cookie_signer.signed_cookie(url_to_be_signed, signing_options)
    end

    def url_to_be_signed
      blob_url(@blob.key)
    end

    def signing_options
      {expires: expiry_time}
    end

    def expiry_time
      10.minutes.from_now
    end
  end
end
