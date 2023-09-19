# frozen_string_literal: true

class ConstraintsController < AuthenticationController
  before_action :set_planning_application
  before_action :ensure_constraint_edits_unlocked, only: %i[edit update]
  before_action :set_planning_application_constraints, only: %i[update]
  before_action :set_removed_constraints, only: %i[update]

  def show; end

  def edit
    @constraints = @planning_application.constraints
    planning_application_constraints = @planning_application.planning_application_constraints.includes(:constraint)
    @constraint_ids = planning_application_constraints.pluck(:constraint_id)
  end

  def update
    ActiveRecord::Base.transaction do
      constraint_ids.each do |constraint_id|
        @planning_application_constraints.find_or_create_by!(constraint_id:)
      end

      @planning_application.update!(updated_address_or_boundary_geojson: true)
      @removed_constraints.destroy_all if @removed_constraints.any?
    end

    redirect_to(after_update_path, notice: t(".success"))
  rescue ActiveRecord::ActiveRecordError => e
    redirect_to planning_application_constraints_path(@planning_application),
                alert: "Couldn't update constraints with error: #{e.message}. Please contact support."
  end

  def check
    @planning_application.constraints_checked!

    respond_to do |format|
      if @planning_application.constraints_checked?
        format.html do
          redirect_to planning_application_validation_tasks_path(@planning_application),
                      notice: t(".success")
        end
      else
        format.html do
          redirect_to planning_application_validation_tasks_path(@planning_application),
                      alert: "Couldn't check constraints - please contact support." # rubocop:disable Rails/I18nLocaleTexts
        end
      end
    end
  end

  private

  def after_update_path
    params.dig(:planning_application, :return_to) || @planning_application
  end

  def constraint_ids
    ids = params[:constraint_ids]

    ids ? ids.map(&:to_i) : []
  end

  def ensure_constraint_edits_unlocked
    render plain: "forbidden", status: :forbidden and return unless @planning_application.can_validate?
  end

  def set_planning_application_constraints
    @planning_application_constraints = @planning_application.planning_application_constraints
  end

  def set_removed_constraints
    removed_constraint_ids = @planning_application_constraints.pluck(:constraint_id).difference(constraint_ids)
    @removed_constraints = @planning_application_constraints.where(constraint_id: removed_constraint_ids)
  end
end
