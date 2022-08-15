# frozen_string_literal: true

class AddUpdateCounterToValidationRequests < ActiveRecord::Migration[6.1]
  VALIDATION_REQUEST_TABLES = %i[
    description_change_validation_requests
    additional_document_validation_requests
    other_change_validation_requests
    red_line_boundary_change_validation_requests
    replacement_document_validation_requests
  ].freeze

  def up
    unless column_exists?(:validation_requests, :update_counter)
      add_column :validation_requests, :update_counter, :boolean, default: false, null: false
    end

    PlanningApplication.all.find_each do |planning_application|
      unless planning_application.valid_red_line_boundary
        update_red_line_boundary_change_validation_request(planning_application)
      end

      update_fee_item_validation_request(planning_application) unless planning_application.valid_fee

      update_counter_for_requests(by_closed_at(planning_application.other_change_validation_requests))

      update_counter_for_requests(updated_replacement_document_validation_requests(planning_application))
    end
  end

  def down
    remove_column :validation_requests, :update_counter, :boolean if column_exists?(:validation_requests,
                                                                                    :update_counter)
  end

  private

  def update_counter_for_requests(requests)
    requests.each do |request|
      update_counter!(request)
    end
  end

  def update_counter!(request)
    request.validation_request.update!(update_counter: true)
  end

  def update_red_line_boundary_change_validation_request(planning_application)
    requests = by_closed_at(planning_application.red_line_boundary_change_validation_requests)

    update_counter!(requests.last) if requests.any?
  end

  def update_fee_item_validation_request(planning_application)
    requests = by_closed_at(planning_application.fee_item_validation_requests)

    update_counter!(requests.last) if requests.any?
  end

  def updated_replacement_document_validation_requests(planning_application)
    requests = planning_application.replacement_document_validation_requests.pre_validation.closed

    new_documents_id = requests.pluck(:new_document_id)

    requests.where.not(old_document_id: new_documents_id)
            .reject(&:new_document_archived?)
            .reject(&:new_document_validated?)
  end

  def by_closed_at(requests)
    requests.pre_validation.closed.sort_by(&:closed_at)
  end
end
