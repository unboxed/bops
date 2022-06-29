# frozen_string_literal: true

class PlanningApplication
  module ValidationRequest
    extend ActiveSupport::Concern

    # since we can't use the native scopes that AASM provides (because
    # #validation_requests is actually the method above rather than a
    # .has_many assocations), add some homemade methods to them.
    #
    # application.open_validation_requests => [reqs...]
    # application.open_validation_requests? => true/false
    %i[open pending closed cancelled].each do |state|
      validation_requests_method = "#{state}_validation_requests"
      post_validation_requests_method = "#{state}_post_validation_requests"

      define_method validation_requests_method do
        validation_requests.select(&:"#{state}?".to_sym)
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

    def validation_requests(post_validation: false)
      (replacement_document_validation_requests + additional_document_validation_requests + other_change_validation_requests + red_line_boundary_change_validation_requests)
        .send(enumerable_method(post_validation), &:post_validation?).sort_by(&:created_at).reverse
    end

    def active_validation_requests(post_validation: false)
      (replacement_document_validation_requests.with_active_document + additional_document_validation_requests + other_change_validation_requests + red_line_boundary_change_validation_requests)
        .reject(&:cancelled?).send(enumerable_method(post_validation), &:post_validation?)
    end

    def open_description_change_requests
      description_change_validation_requests.open
    end

    def latest_auto_closed_description_request
      description_change_validation_requests.order(created_at: :desc).select(&:auto_closed?).first
    end

    def latest_rejected_description_change
      description_change_validation_requests.order(created_at: :desc).select(&:rejected?).first
    end

    def last_validation_request_date
      closed_validation_requests.max_by(&:updated_at).updated_at
    end

    def overdue_requests
      validation_requests.select(&:open?).select(&:overdue?)
    end

    private

    def no_open_post_validation_requests?
      !open_post_validation_requests?
    end

    def enumerable_method(post_validation)
      post_validation ? "select" : "reject"
    end
  end
end
