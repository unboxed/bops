# frozen_string_literal: true

class ConstraintsController < AuthenticationController
  before_action :set_planning_application
  before_action :ensure_constraint_edits_unlocked, only: %i[show update]
  before_action :set_planning_application_constraints, only: %i[update]

  def show; end

  def update
    ActiveRecord::Base.transaction do
      @planning_application_constraints.each do |pac|
        if constraints_to_remove.include?(pac.constraint_id)
          if pac.identified?
            pac.update!(removed_at: Time.current)
          else
            pac.destroy
          end
        elsif pac.identified? && pac.removed_at?
          pac.update!(removed_at: nil) if constraint_ids.include?(pac.constraint_id)
        end
      end

      constraints_to_add.each do |constraint_id|
        @planning_application_constraints.create!(
          constraint_id:,
          identified_by: current_user.name
        )
      end

      @planning_application.update!(updated_address_or_boundary_geojson: true)

      @planning_application.constraints_checked!
    end

    respond_to do |format|
      if @planning_application.constraints_checked?
        format.html do
          redirect_to planning_application_validation_tasks_path(@planning_application),
                      notice: t(".success")
        end
      else
        format.html do
          redirect_to planning_application_validation_tasks_path(@planning_application),
                      alert: t(".failure")
        end
      end
    end
  rescue ActiveRecord::ActiveRecordError => e
    redirect_to planning_application_constraints_path(@planning_application),
                alert: "Couldn't update constraints with error: #{e.message}. Please contact support."
  end

  private

  def ensure_constraint_edits_unlocked
    render plain: "forbidden", status: :forbidden and return unless @planning_application.can_validate?
  end

  def set_planning_application_constraints
    @planning_application_constraints = @planning_application.planning_application_constraints
  end

  def constraint_ids
    @constraint_ids ||= Array.wrap(params[:constraint_ids]).map { |id| Integer(id) }
  end

  def existing_constraint_ids
    @existing_constraint_ids ||= @planning_application_constraints.map(&:constraint_id)
  end

  def constraints_to_add
    @constraints_to_add ||= constraint_ids - existing_constraint_ids
  end

  def constraints_to_remove
    @constraints_to_remove ||= existing_constraint_ids - constraint_ids
  end
end
