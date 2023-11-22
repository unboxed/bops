# frozen_string_literal: true

class PlanningApplication < ApplicationRecord
  module ValidationRequests
    extend ActiveSupport::Concern

    # since we can't use the native scopes that AASM provides (because
    # #validation_requests is a method we use to load all validation requests rather than a
    # .has_many assocations), add some homemade methods to them.
    #
    # application.open_validation_requests => [reqs...]
    # application.open_validation_requests? => true/false
    %i[open pending closed cancelled].each do |state|
      validation_requests_method = "#{state}_validation_requests"
      post_validation_requests_method = "#{state}_post_validation_requests"

      define_method validation_requests_method do
        validation_requests.where(state: "#{state}")
      end

      define_method post_validation_requests_method do
        validation_requests(post_validation: true).select(&:"#{state}?".to_sym)
      end

      define_method "#{validation_requests_method}?" do
        send(validation_requests_method).any?
      end

      define_method "#{post_validation_requests_method}?" do
        send(post_validation_requests_method).any?
      end
    end

    def open_description_change_requests
      description_change_validation_requests.open
    end

    def latest_auto_closed_description_request
      description_change_validation_requests.order(created_at: :desc).find(&:auto_closed?)
    end

    def latest_rejected_description_change
      description_change_validation_requests.order(created_at: :desc).find(&:rejected?)
    end

    def last_validation_request_date
      closed_validation_requests.max_by(&:updated_at).updated_at
    end

    def overdue_requests
      validation_requests.where(state: ["open", "overdue"])
    end

    def reset_validation_requests_update_counter!(requests)
      return unless requests.any?

      requests.pre_validation.with_validation_request.filter(&:update_counter?).each(&:reset_update_counter!)
    end

    def all_open_post_validation_requests
      validation_requests(post_validation: true, include_description_change_validation_requests: true).select(&:open?)
    end

    ValidationRequest::VALIDATION_REQUEST_TYPES.map(&:underscore).each do |type|
      define_method(type) do
        send(type.pluralize).order(:created_at).last
      end
    end

    private

    def no_open_post_validation_requests?
      !open_post_validation_requests?
    end

    def enumerable_method(post_validation)
      post_validation ? "select" : "reject"
    end

    def validation_request_types(include_description_change: true)
      [
        :additional_document,
        (:description_change if include_description_change),
        :other,
        :red_line_boundary_change,
        :replacement_document
      ].compact
    end
  end
end
