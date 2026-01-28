# frozen_string_literal: true

module Tasks
  class Form
    include ActiveModel::API
    include ActiveModel::Validations::Callbacks
    include ActiveModel::Attributes
    include ActiveRecord::AttributeAssignment
    include BopsCore::Model::Access
    include BopsCore::Model::BeforeTypeCast

    include Rails.application.routes.url_helpers

    attr_reader :task, :params, :return_to
    attr_accessor :action

    delegate :case_record, :slug, to: :task
    delegate :planning_application, to: :case_record
    delegate :local_authority, to: :planning_application
    delegate :param_key, to: :model_name

    define_model_callbacks :initialize, only: :after
    define_model_callbacks :update

    with_options instance_writer: false do
      class_attribute :task_actions, default: %w[save_and_complete]
      class_attribute :after_success, default: "redirect"
      class_attribute :after_failure, default: "render"
    end

    def initialize(task, params = {})
      @task = task
      @params = params
      @result = false
      @action = "default"
      @return_to = params[:return_to].presence

      run_callbacks :initialize do
        super({})
      end
    end

    def persisted?
      true
    end

    def update(params)
      assign_attributes(form_params(params))

      self.action = validate_task_action(params)
      return false unless valid?(action.to_sym)

      run_callbacks :update do
        @result = block_given? ? !!yield(params) : true
      end

      @result
    rescue ActiveRecord::ActiveRecordError => e
      report_error(e) and return false
    end

    def url(options = {})
      route_for(:task, planning_application, task, **options.with_defaults(only_path: true))
    end

    def redirect_url(options = {})
      return return_to if return_to.present?

      route_for(:task, planning_application, task, **options.with_defaults(only_path: true))
    end

    def permitted_fields(params)
      params
    end

    def flash(type, controller)
      return if action == "edit_form"

      case type
      when :notice
        (after_success == "redirect") ? controller.t(".#{slug}.success") : nil
      when :alert
        (after_failure == "redirect") ? controller.t(".#{slug}.failure") : nil
      end
    end

    def read_only?
      task.status == "completed"
    end

    private

    def form_params(params)
      params.fetch(param_key, {}).permit(attribute_names)
    end

    def transaction(&block)
      ActiveRecord::Base.transaction(&block)
    end

    def validate_task_action(params)
      action = params.fetch(:task_action, "missing").to_s

      if task_actions.include?(action)
        action
      else
        raise ArgumentError, "Invalid task action: #{action.inspect}"
      end
    end

    def report_error(error)
      # If we get here that means we've missed something so send it to Appsignal
      Appsignal.send_exception(error)

      # Let the user know that we couldn't carry out the action
      errors.add :base, :invalid, message: "Unable to perform action - please contact support"
    end

    def save_draft
      task.start!
    end

    def save_and_complete
      task.complete!
    end

    def edit_form
      task.in_progress!
    end
  end
end
