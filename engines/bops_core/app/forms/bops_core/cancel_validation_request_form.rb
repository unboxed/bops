# frozen_string_literal: true

module BopsCore
  class CancelValidationRequestForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :cancel_reason, :string

    attr_reader :planning_application, :task, :validation_request

    def initialize(planning_application:, task:, validation_request:, **attributes)
      @planning_application = planning_application
      @task = task
      @validation_request = validation_request
      super(attributes)
    end

    validates :cancel_reason, presence: {message: "Explain to the applicant why this request is being cancelled"}

    def save
      return false unless valid?

      ActiveRecord::Base.transaction do
        validation_request.assign_attributes(cancel_reason:)
        validation_request.cancel_request!
        validation_request.send_cancelled_validation_request_mail unless planning_application.not_started?
        task.not_started!
      end
      true
    rescue ActiveRecord::ActiveRecordError => e
      Appsignal.report_error(e)
      errors.add(:base, "Unable to cancel request - please contact support")
      false
    end
  end
end
