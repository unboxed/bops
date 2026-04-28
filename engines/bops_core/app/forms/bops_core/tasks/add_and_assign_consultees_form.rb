# frozen_string_literal: true

module BopsCore
  module Tasks
    module AddAndAssignConsulteesForm
      extend ActiveSupport::Concern

      included do
        self.task_actions = %w[
          default save_draft save_and_complete
          edit_consultees add_consultee remove_consultee
          update_constraint add_constraint_consultee remove_constraint_consultee
        ]

        delegate :consultation, to: :planning_application

        attribute :consultation_required, :boolean, default: true
        attribute :contact_id, :integer
        attribute :consultee_id, :integer

        alias_method :consultation_required?, :consultation_required

        with_options on: :update_constraint do
          validates :consultation_required, inclusion: {in: [true, false], message: "Choose whether the constraint needs to be consulted on or not"}

          validate if: :consultation_required? do
            if constraint.consultees.empty?
              errors.add(:consultation_required, :blank, message: "Consultees are required for this constraint")
            end
          end
        end

        after_initialize do
          if editing_constraint?
            self.consultation_required = constraint.consultation_required
          end
        end
      end

      def contact
        @contact ||= Contact.find(contact_id)
      end

      def consultee
        @consultee ||= find_consultee
      end

      def constraints
        @constraints ||= planning_application.planning_application_constraints.includes(:consultees)
      end

      def constraint
        @constraint ||= constraints.find(params[:id])
      end

      def constraint_url(options = {})
        route_for(:task_component, planning_application, slug: task.full_slug, id: constraint.id, **options.with_defaults(only_path: true))
      end

      def remove_consultee_url(consultee)
        options = {
          "#{param_key}[consultee_id]" => consultee.to_param,
          "#{param_key}[consultation_required]" => consultation_required.to_param
        }

        if editing_constraint?
          route_for(:task_component, planning_application, slug: task.full_slug, id: constraint.id, **options.with_defaults(task_action: "remove_constraint_consultee", only_path: true))
        else
          route_for(:task, planning_application, slug: task.full_slug, **options.with_defaults(task_action: "remove_consultee", only_path: true))
        end
      end

      def consultees
        @consultees ||= find_consultees
      end

      def after_success
        case action
        when "add_consultee", "remove_consultee"
          "render_with_flash"
        when "add_constraint_consultee", "remove_constraint_consultee"
          "render_with_flash"
        when "edit_consultees"
          "render"
        else
          "redirect"
        end
      end

      def success_template
        editing_constraint? ? :edit : :show
      end

      def failure_template
        editing_constraint? ? :edit : :show
      end

      private

      def editing_constraint?
        params.key?(:id)
      end

      def find_consultee
        if editing_constraint?
          constraint.consultees.find(consultee_id)
        else
          consultation.consultees.find(consultee_id)
        end
      end

      def find_consultees
        if editing_constraint?
          constraint.consultees
        else
          consultation.consultees.unassigned
        end
      end

      def edit_consultees
        true
      end

      def contact_params
        {
          name: contact.name,
          organisation: contact.organisation,
          role: contact.role,
          email_address: contact.email_address,
          origin: contact.origin
        }
      end

      def add_constraint_consultee
        constraint.consultees << consultation.consultees.create!(contact_params)
      rescue ActiveRecord::ActiveRecordError
        false
      end

      def remove_constraint_consultee
        consultee.destroy! && consultees.reload
      rescue ActiveRecord::ActiveRecordError
        false
      end

      def add_consultee
        consultation.consultees.create!(contact_params)
      rescue ActiveRecord::ActiveRecordError
        false
      end

      def remove_consultee
        consultee.destroy! && consultees.reload
      rescue ActiveRecord::ActiveRecordError
        false
      end

      def update_constraint
        constraint.update!(consultation_required:)
      rescue ActiveRecord::ActiveRecordError
        false
      end
    end
  end
end
